// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";


import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

contract CreatePool is Script {
    function run() external {
        address poolManager = vm.envAddress("POOL_MANAGER");     // Uniswap V4 PoolManager
        address token0 = vm.envAddress("UNDERLYING");            // WETH
        address token1 = vm.envAddress("TOKEN1");                // USDC
        address hook = vm.envAddress("YIELD_HOOK");              // your Hook address

        // Price = 1:1 (WETH:USDC)
        uint160 sqrtPriceX96 = 79228162514264337593543950336;

        vm.startBroadcast();

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 10,
            hooks: IHooks(hook)
        });

        IPoolManager(poolManager).initialize(key, sqrtPriceX96);

        vm.stopBroadcast();

        console.log("POOL CREATED with hook:", hook);
    }
}

