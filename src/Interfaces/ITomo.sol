// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;



interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface IFeeSplitter {
    function distribute(address token, uint256 amount) external;
}

/// Minimal LRT adapter interface (same as adapter)
interface ILRT {
    function deposit(uint256 amount) external returns (uint256);
    function withdraw(uint256 shares) external returns (uint256);
    function previewWithdraw(uint256 shares) external view returns (uint256);

}
