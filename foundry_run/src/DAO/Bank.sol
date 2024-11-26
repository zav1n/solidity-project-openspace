// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    receive() external payable {}

    function withdraw(address to, uint256 amount) external {
        require(msg.sender == admin, "Only admin can withdraw");
        require(address(this).balance >= amount, "Insufficient balance");
        payable(to).transfer(amount);
    }

    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only admin can set admin");
        admin = newAdmin;
    }
}