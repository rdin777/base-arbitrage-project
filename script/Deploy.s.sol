// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ArbitrageExecutor.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Router addresses on Base Mainnet
        address uniswapRouter = 0x2626664c2603336E57B271c5C0b26F421741e481; // Uniswap V3 SwapRouter (Base)
        address aerodromeRouter = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43; // Aerodrome Router
        address flashLoanPool = 0x4C36388bE6F416A29C8d8Eee81c771CE6Be14B18; // Flash loan pool
        
        uint256 minProfit = 0.001 ether;
        
        vm.startBroadcast(deployerPrivateKey);
        
        ArbitrageExecutor executor = new ArbitrageExecutor(
            uniswapRouter,
            aerodromeRouter,
            flashLoanPool,
            minProfit
        );
        
        vm.stopBroadcast();
        
        console.log("ArbitrageExecutor deployed to:", address(executor));
        console.log("Owner:", vm.addr(deployerPrivateKey));
        console.log("Min profit:", minProfit);
    }
}
