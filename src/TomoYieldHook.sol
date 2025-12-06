// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// FIX: Add the import for the shared interfaces to resolve Undeclared identifier errors (7576)
import "./interfaces/ITomo.sol"; 

import {BaseHook} from "v4-periphery/utils/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";


/**
 * @title TomoYieldHook
 * @notice After-swap hook (afterSwap) + yield manager entrypoint.
 * - This hook deposits received yield into an LRT via the router.
 */
contract TomoYieldHook is BaseHook {
    
    // --- State Variables ---
    address public owner;

    // The underlying token we accept for deposits (e.g., WETH)
    // FIX: Changed to SCREAMING_SNAKE_CASE for immutable variable
    address public immutable UNDERLYING_TOKEN;

    // optional FeeSplitter address (used as address type to avoid conflict on IFeeSplitter type)
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

    // FIX: Refactored logic into internal function for gas optimization
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
        // NOTE: The self-validation check for HookAddressValid is typically removed here to allow standard deployment
        // If it was present: require(_poolManager.isHookAddressValid(address(this)), "HookAddressNotValid"); 
        
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

    /**
     * @notice Passive on-swap. This hook intentionally does very little on-swap to reduce gas.
     * FIX: Added pure mutability
     */
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

    // ------------------------------------------------------------------------------------
    // External entrypoint for FeeSplitter (or other sender) to deposit tokens and deposit to LRT
    // ------------------------------------------------------------------------------------
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

        // Approve the LRT adapter to pull tokens
        // FIX: Added require check for unchecked ERC20 transfer/approve
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

    /// @notice Harvest: withdraw some shares and either send underlying to feeSplitter for distribution or to owner
    function harvestAndDistribute(uint256 sharesToWithdraw, bool routeToFeeSplitter, address recipientIfNotSplitter) external onlyOwner {
        require(sharesToWithdraw > 0, "zero");
        require(sharesToWithdraw <= lrtShares, "insufficient shares");

        // withdraw underlying using the imported ILRT interface
        uint256 withdrawn = ILRT(lrtRouter).withdraw(sharesToWithdraw);
        lrtShares -= sharesToWithdraw;

        emit YieldHarvested(withdrawn);

        // route the withdrawn tokens
        if (routeToFeeSplitter && feeSplitterAddress != address(0)) {
            // send underlying to feeSplitter and instruct it to distribute
            // FIX: Added require check for unchecked ERC20 approve
            require(IERC20(UNDERLYING_TOKEN).approve(feeSplitterAddress, withdrawn), "TH: approve splitter failed"); // FIX: Used new immutable name
            
            // Call distribute using the imported IFeeSplitter interface
            try IFeeSplitter(feeSplitterAddress).distribute(UNDERLYING_TOKEN, withdrawn) { // FIX: Used new immutable name
                // distributed
            } catch {
                // if distribute fails, transfer to owner
                // FIX: Added require check for unchecked ERC20 transfer
                require(IERC20(UNDERLYING_TOKEN).transfer(owner, withdrawn), "TH: transfer owner failed"); // FIX: Used new immutable name
            }
        } else {
            // direct transfer to recipient
            address dest = recipientIfNotSplitter == address(0) ? owner : recipientIfNotSplitter;
            // FIX: Added require check for unchecked ERC20 transfer
            require(IERC20(UNDERLYING_TOKEN).transfer(dest, withdrawn), "TH: transfer dest failed"); // FIX: Used new immutable name
        }
    }

    // Admin functions
    function setFeeSplitter(address _feeSplitter) external onlyOwner {
        feeSplitterAddress = _feeSplitter;
        emit FeeSplitterSet(_feeSplitter);
    }

    function setLrtRouter(address _router) external onlyOwner {
        require(_router != address(0), "zero");
        // careful: resetting accounting if you want to migrate must be handled
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
        // FIX: Added require check for unchecked ERC20 transfer
        require(IERC20(UNDERLYING_TOKEN).transfer(owner, amount), "TH: emergency failed"); // FIX: Used new immutable name
    }
}