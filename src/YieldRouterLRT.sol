// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import "./interfaces/ITomo.sol"; 


contract YieldRouterLRT {
  
    
    address public immutable lrt;         // LRT contract (ezETH)
    address public immutable token;       
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

    
    function depositToLRT(uint256 amount) public onlyOwner returns (uint256) {
        require(amount > 0, "zero");
        // approve LRT using the imported IERC20 interface
        require(IERC20(token).approve(lrt, amount), "approve failed");

        // call LRT.deposit(amount) using the imported ILRT interface
        uint256 shares = ILRT(lrt).deposit(amount);

        emit DepositedToLRT(msg.sender, amount, shares);
        return shares;
    }

    
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
