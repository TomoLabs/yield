// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "./interfaces/ITomo.sol"; 

import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";



contract TomoYieldHook is BaseHook {
    
    // --- State Variables ---
    address public owner;

    
    address public immutable UNDERLYING_TOKEN;

    // FeeSplitter address (used as address type to avoid conflict on IFeeSplitter type)
    address public feeSplitterAddress;

    // LRT adapter address (YieldRouterLRT)
    address public lrtRouter;

    // Minimum deposit threshold to avoid tiny deposits
    uint256 public minDeposit;

    // mapping for accounting shares: how many LRT shares this contract holds (tracked by router)
    uint256 public lrtShares;

    // --- Events ---
    event ReceivedForYield(address indexed token, uint256 amount);
    event DepositedToLRT(uint256 amount, uint256 shares);
    event YieldHarvested(uint256 withdrawnAmount);
    event FeeSplitterSet(address splitter);
    event OwnerChanged(address oldOwner, address newOwner);
    event MinDepositUpdated(uint256 newMin);

    // Refactored logic into internal function for gas optimization
    function _onlyOwner() internal view {
        require(msg.sender == owner, "not owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    constructor(IPoolManager _poolManager, address _underlyingToken, address _lrtRouter, address _feeSplitter, uint256 _minDeposit)
        BaseHook(_poolManager)
    {
        
        
        require(_underlyingToken != address(0), "zero token");
        require(_lrtRouter != address(0), "zero router");
        
        UNDERLYING_TOKEN = _underlyingToken;
        lrtRouter = _lrtRouter;
        feeSplitterAddress = _feeSplitter; 
        minDeposit = _minDeposit;
        owner = msg.sender;
    }

    /// Hook permissions - only afterSwap
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true, // Only this is active
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    
    function _afterSwap(
        address, // caller
        PoolKey calldata, // key
        SwapParams calldata, // params
        BalanceDelta delta,
        bytes calldata
    ) internal pure override returns (bytes4, int128) {
        int128 raw = delta.amount0();
        if (raw != 0) {
            // Placeholder logic for potential future use or signaling
        }
        return (BaseHook.afterSwap.selector, 0);
    }

    
    // External entrypoint for FeeSplitter (or other sender) to deposit tokens and deposit to LRT
    
    function receiveAndDeposit(address token, uint256 amount) external returns (bool) {
        // allow only the configured feeSplitter or owner to call this
        require(msg.sender == feeSplitterAddress || msg.sender == owner, "not authorized");
        require(token == UNDERLYING_TOKEN, "unexpected token"); // FIX: Used new immutable name
        require(amount > 0, "zero");

        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal >= amount, "insufficient balance");

        emit ReceivedForYield(token, amount);

        // Only deposit if above threshold
        if (amount < minDeposit) {
            // leave the funds on contract until threshold met
            return false;
        }

        
        require(IERC20(token).approve(lrtRouter, amount), "TH: approve failed");

        // Call router deposit using the imported ILRT interface
        try ILRT(lrtRouter).deposit(amount) returns (uint256 shares) {
            lrtShares += shares;
            emit DepositedToLRT(amount, shares);
            return true;
        } catch {
            // if deposit failed, keep funds in contract for later attempt
            return false;
        }
    }

    
    function harvestAndDistribute(uint256 sharesToWithdraw, bool routeToFeeSplitter, address recipientIfNotSplitter) external onlyOwner {
        require(sharesToWithdraw > 0, "zero");
        require(sharesToWithdraw <= lrtShares, "insufficient shares");

        // withdraw underlying using the imported ILRT interface
        uint256 withdrawn = ILRT(lrtRouter).withdraw(sharesToWithdraw);
        lrtShares -= sharesToWithdraw;

        emit YieldHarvested(withdrawn);

        // route the withdrawn tokens
        if (routeToFeeSplitter && feeSplitterAddress != address(0)) {
            require(IERC20(UNDERLYING_TOKEN).approve(feeSplitterAddress, withdrawn), "TH: approve splitter failed"); 
            
            // Call distribute using the imported IFeeSplitter interface
            try IFeeSplitter(feeSplitterAddress).distribute(UNDERLYING_TOKEN, withdrawn) { 
                // distributed
            } catch {
                require(IERC20(UNDERLYING_TOKEN).transfer(owner, withdrawn), "TH: transfer owner failed"); 
            }
        } else {
            // direct transfer to recipient
            address dest = recipientIfNotSplitter == address(0) ? owner : recipientIfNotSplitter;
            require(IERC20(UNDERLYING_TOKEN).transfer(dest, withdrawn), "TH: transfer dest failed"); 
        }
    }

    // Admin functions
    function setFeeSplitter(address _feeSplitter) external onlyOwner {
        feeSplitterAddress = _feeSplitter;
        emit FeeSplitterSet(_feeSplitter);
    }

    function setLrtRouter(address _router) external onlyOwner {
        require(_router != address(0), "zero");
        lrtShares = 0; 
        lrtRouter = _router;
    }

    function setMinDeposit(uint256 _min) external onlyOwner {
        minDeposit = _min;
        emit MinDepositUpdated(_min);
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    // emergency withdraw underlying from this contract to owner
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(IERC20(UNDERLYING_TOKEN).transfer(owner, amount), "TH: emergency failed");
    }

}
