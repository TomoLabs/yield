// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// FIX: Import the shared interfaces file to resolve "Identifier already declared" errors (2333)
import "./interfaces/ITomo.sol"; 
// Note: This file must contain the definitions for IERC20 and ILRT.

contract YieldRouterLRT {
    // Note: IERC20 and ILRT interface definitions were removed here to prevent conflicts.
    
    address public immutable lrt;         // LRT contract (ezETH)
    address public immutable token;       // underlying ERC20 (e.g., WETH) - or 0 for native ETH (requires changes)
    address public owner;

    event DepositedToLRT(address indexed from, uint256 amount, uint256 shares);
    event WithdrawnFromLRT(address indexed to, uint256 shares, uint256 amount);
    event OwnerChanged(address oldOwner, address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _lrt, address _token) {
        require(_lrt != address(0), "zero lrt");
        lrt = _lrt;
        token = _token;
        owner = msg.sender;
    }

    /// @notice deposit `amount` of underlying token into LRT and return shares
    /// Caller must ensure this contract has `amount` tokens (transfer first).
    function depositToLRT(uint256 amount) public onlyOwner returns (uint256) {
        require(amount > 0, "zero");
        // approve LRT using the imported IERC20 interface
        require(IERC20(token).approve(lrt, amount), "approve failed");

        // call LRT.deposit(amount) using the imported ILRT interface
        uint256 shares = ILRT(lrt).deposit(amount);

        emit DepositedToLRT(msg.sender, amount, shares);
        return shares;
    }

    /// @notice withdraw given shares from LRT, returns withdrawn underlying amount
    function withdrawFromLRT(uint256 shares) public onlyOwner returns (uint256) {
        require(shares > 0, "zero");
        // call LRT.withdraw(shares) using the imported ILRT interface
        uint256 amount = ILRT(lrt).withdraw(shares);
        emit WithdrawnFromLRT(msg.sender, shares, amount);
        return amount;
    }

    function setOwner(address newOwner) external onlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    /// view helper - preview withdraw
    function previewWithdraw(uint256 shares) external view returns (uint256) {
        // call LRT.previewWithdraw(shares) using the imported ILRT interface
        return ILRT(lrt).previewWithdraw(shares);
    }
}