// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Interface for flash loans (EIP-3156 standard)
interface IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);
    function flashFee(address token, uint256 amount) external view returns (uint256);
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// Uniswap V3 Router interface for swaps
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract ArbitrageExecutor is IERC3156FlashBorrower, Ownable {
    using SafeERC20 for IERC20;

    // Router and pool addresses for flash loans
    address public uniswapRouter;
    address public aerodromeRouter;
    address public flashLoanPool;
    
    // Minimum profit for execution (in wei)
    uint256 public minProfit;
    
    // Owner's balance (accumulated profit from arbitrage)
    mapping(address => uint256) public balances;

    // === EVENTS ===
    event ArbitrageExecuted(
        address indexed tokenBorrowed,
        uint256 amountBorrowed,
        uint256 profit,
        uint256 amountOutFromFirstSwap,
        uint256 amountOutFromSecondSwap
    );
    
    event FundsWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount
    );
    
    event MinProfitUpdated(uint256 oldMinProfit, uint256 newMinProfit);
    
    event RoutersUpdated(
        address oldUniswap, 
        address oldAerodrome, 
        address newUniswap, 
        address newAerodrome
    );

    constructor(
        address _uniswapRouter,
        address _aerodromeRouter,
        address _flashLoanPool,
        uint256 _minProfit
    ) Ownable(msg.sender) {
        require(_uniswapRouter != address(0), "Invalid uniswap router");
        require(_aerodromeRouter != address(0), "Invalid aerodrome router");
        require(_flashLoanPool != address(0), "Invalid flash loan pool");
        
        uniswapRouter = _uniswapRouter;
        aerodromeRouter = _aerodromeRouter;
        flashLoanPool = _flashLoanPool;
        minProfit = _minProfit;
    }

    // === FLASH LOAN FUNCTION (called by the pool after token transfer) ===
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        // Check: only our contract can initiate a flash loan.
        require(initiator == address(this), "Unauthorized initiator");
        
        // Decoding arbitrage parameters
        (
            address tokenIn,
            address tokenOut,
            uint24 fee1,
            uint24 fee2,
            uint256 amountOutMinimum
        ) = abi.decode(data, (address, address, uint24, uint24, uint256));
        
        // Allowing routers to spend tokens
        IERC20(token).forceApprove(uniswapRouter, amount);
        IERC20(token).forceApprove(aerodromeRouter, amount);
        
        // Checking the balance before swaps.
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(balanceBefore >= amount + fee, "Insufficient balance for flash loan repayment");
        
        // SWAP 1: Buy tokenOut on Uniswap (cheaper)
        uint256 amountOut1 = ISwapRouter(uniswapRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee1,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            })
        );
        
        // We obtain the amount of tokenOut after the first swap.
        uint256 tokenOutAmount = IERC20(tokenOut).balanceOf(address(this));
        
        // Allow Aerodrome to spend tokenOut.
        IERC20(tokenOut).forceApprove(aerodromeRouter, tokenOutAmount);
        
        // SWAP 2: Sell tokenOut on Aerodrome (at a higher price), receive tokenIn in return.
        uint256 amountOut2 = ISwapRouter(aerodromeRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenOut,
                tokenOut: tokenIn,
                fee: fee2,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: tokenOutAmount,
                amountOutMinimum: amount + fee + minProfit,
                sqrtPriceLimitX96: 0
            })
        );
        
        // Checking the balance after swaps
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        
        // Calculating profit
        uint256 profit = balanceAfter - (amount + fee);
        require(profit >= minProfit, "Insufficient profit");
        
        // We record the profit on the owner's balance sheet (effects)
        balances[token] += profit;

        // Repaying the flash loan with the fee (interactions)
        IERC20(token).safeTransfer(flashLoanPool, amount + fee);

        emit ArbitrageExecuted(token, amount, profit, amountOut1, amountOut2);
        
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    // === Public function to launch arbitrage ===
    function executeArbitrage(
        address tokenBorrow,
        uint256 amount,
        address tokenIn,
        address tokenOut,
        uint24 fee1,
        uint24 fee2
    ) external onlyOwner {
        // Encoding parameters for a flash loan
        bytes memory data = abi.encode(
            tokenIn,
            tokenOut,
            fee1,
            fee2,
            0 // amountOutMinimum will be checked inside onFlashLoan
        );
        
        // We take out a flash loan and check the result.
        bool success = IERC3156FlashLender(flashLoanPool).flashLoan(
            this,
            tokenBorrow,
            amount,
            data
        );
        require(success, "Flash loan failed");
    }

    // === PROFIT WITHDRAWAL ===
    function withdraw(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(balances[token] >= amount, "Insufficient balance");
        balances[token] -= amount;
        IERC20(token).safeTransfer(to, amount);
        emit FundsWithdrawn(token, to, amount);
    }

    // === CONTROL ===
    function setMinProfit(uint256 _minProfit) external onlyOwner {
        uint256 oldMinProfit = minProfit;
        minProfit = _minProfit;
        emit MinProfitUpdated(oldMinProfit, _minProfit);
    }
    
    function setRouters(address _uniswap, address _aerodrome) external onlyOwner {
        require(_uniswap != address(0), "Invalid uniswap router");
        require(_aerodrome != address(0), "Invalid aerodrome router");
        
        address oldUniswap = uniswapRouter;
        address oldAerodrome = aerodromeRouter;
        uniswapRouter = _uniswap;
        aerodromeRouter = _aerodrome;
        emit RoutersUpdated(oldUniswap, oldAerodrome, _uniswap, _aerodrome);
    }

    // Retrieving the contract balance (for debugging)
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
