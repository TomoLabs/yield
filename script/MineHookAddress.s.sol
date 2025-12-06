// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "v4-periphery/utils/HookMiner.sol";

import "../src/TomoYieldHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract MineHookAddress is Script {
    function run() external {
        address poolManager = vm.envAddress("POOL_MANAGER");
        address underlying = vm.envAddress("UNDERLYING");
        address lrt = vm.envAddress("LRT_ADDR");
        address feeSplitter = vm.envAddress("FEE_SPLITTER");
        uint256 minDeposit = vm.envUint("MIN_DEPOSIT");

        // Build init code
        bytes memory initCode = abi.encodePacked(
            type(TomoYieldHook).creationCode,
            abi.encode(
                IPoolManager(poolManager),
                underlying,
                lrt,
                feeSplitter,
                minDeposit
            )
        );

        // Build permissions
        Hooks.Permissions memory perms = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });

        // Convert permissions → bitmap
        uint160 bitmap = perms.toBitmap();

        // Desired hook address must satisfy:
        // hook & HOOK_MASK == bitmap
        address desired = address(bitmap);

        // Mine the salt
        bytes32 salt = HookMiner.find(desired, initCode);

        // Compute final hook address
        address hookAddress = HookMiner.computeAddress(desired, salt, initCode);

        console.log("DESIRED PATTERN:", desired);
        console.log("FOUND VALID HOOK ADDRESS:", hookAddress);
        console.log("SALT:", uint256(salt));
    }
}
