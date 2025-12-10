// File: script/DeployTomoYield.s.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/YieldRouterLRT.sol"; 
import "../src/TomoYieldHook.sol";  
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract DeployTomoYield is Script {
    function run() external {
        // Read env variables (MUST be set via 'export' or a .env file)
        address poolManager = vm.envAddress("POOL_MANAGER"); 
        address lrt = vm.envAddress("LRT_ADDR");             
        address underlying = vm.envAddress("UNDERLYING");   
        address feeSplitter = vm.envAddress("FEE_SPLITTER"); 
        uint256 minDeposit = vm.envUint("MIN_DEPOSIT");      
        
        

        // Start broadcasting deployment transactions
        vm.startBroadcast(); 

        // 1) Deploy YieldRouterLRT
        YieldRouterLRT router = new YieldRouterLRT(lrt, underlying);
        console.log("YieldRouterLRT deployed at:", address(router));

        // 2) Deploy TomoYieldHook
        TomoYieldHook hook = new TomoYieldHook(
            IPoolManager(poolManager), 
            underlying, 
            address(router), 
            feeSplitter, 
            minDeposit
        );
        console.log("TomoYieldHook deployed at:", address(hook));

        vm.stopBroadcast();
    }
}
