// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ArbitrageExecutor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArbitrageExecutorTest is Test {
    ArbitrageExecutor public executor;
    
    // Test addresses
    address public owner = address(0x1);
    address public uniswapRouter = address(0x2);
    address public aerodromeRouter = address(0x3);
    address public flashLoanPool = address(0x4);
    
    function setUp() public {
        // Deploy the contract before each test.
        vm.prank(owner);
        executor = new ArbitrageExecutor(
            uniswapRouter,
            aerodromeRouter,
            flashLoanPool,
            1 ether // minProfit = 1 ETH
        );
    }
    
    // Test 1: Deployment check
    function test_Deployment() public view {
        assertEq(executor.owner(), owner, "Owner should be deployer");
        assertEq(executor.uniswapRouter(), uniswapRouter, "Uniswap router should be set");
        assertEq(executor.aerodromeRouter(), aerodromeRouter, "Aerodrome router should be set");
        assertEq(executor.flashLoanPool(), flashLoanPool, "Flash loan pool should be set");
        assertEq(executor.minProfit(), 1 ether, "Min profit should be 1 ETH");
    }
    
    // Test 2: Changing minProfit
    function test_SetMinProfit() public {
        uint256 newMinProfit = 2 ether;
        
        vm.prank(owner);
        executor.setMinProfit(newMinProfit);
        
        assertEq(executor.minProfit(), newMinProfit, "Min profit should be updated");
    }
    
    // Test 3: Only the owner can change minProfit.
    function test_RevertIf_NotOwnerSetMinProfit() public {
    address attacker = address(0x999);
    
    vm.prank(attacker);
    vm.expectRevert(
        abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            attacker
        )
    );
    executor.setMinProfit(2 ether);
}
    
    // Test 4: Changing routers
    function test_SetRouters() public {
        address newUniswap = address(0x5);
        address newAerodrome = address(0x6);
        
        vm.prank(owner);
        executor.setRouters(newUniswap, newAerodrome);
        
        assertEq(executor.uniswapRouter(), newUniswap, "Uniswap router should be updated");
        assertEq(executor.aerodromeRouter(), newAerodrome, "Aerodrome router should be updated");
    }
    
    // Test 5: Cannot set the router address to zero.
    function test_RevertIf_ZeroAddressRouter() public {
        vm.prank(owner);
        vm.expectRevert("Invalid uniswap router");
        executor.setRouters(address(0), address(0x6));
        
        vm.prank(owner);
        vm.expectRevert("Invalid aerodrome router");
        executor.setRouters(address(0x5), address(0));
    }
    
    // Test 6: Token balance check
    function test_GetTokenBalance() public {
        // Create a mock token
        MockToken token = new MockToken();
        
        // Check the initial balance (it should be 0).
        assertEq(executor.getTokenBalance(address(token)), 0, "Initial balance should be 0");
    }
}

// Mock token for testing
contract MockToken {
    mapping(address => uint256) public balanceOf;
    
    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
    }
}
