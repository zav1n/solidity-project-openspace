// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Bank } from "./Bank.sol";

contract BigBank is Bank {
    uint256 private immutable MIN_DEPOSIT = 1e6 gwei;

    event updateOnwer(address, address);

    function deposit() public payable override {
        require(msg.value > MIN_DEPOSIT, "more than 0.001 ETH");
        super.deposit();
    }

    function transferOwnership(address newAddr) external {
        require(newAddr != address(0), "invalid address");
        require(newAddr != admin, "exists the address");
        address oldAddress = admin;
        admin = newAddr;
        emit updateOnwer(oldAddress, newAddr);
    }
}

