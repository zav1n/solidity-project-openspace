// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Demo {
    uint256 count;
    uint256 private pk;

    struct PortfolioHeader {
      string name;
      uint256 value;
    }
    PortfolioHeader public information;

    constructor() {
      information.name = "tttttest";
      information.value = 100;
    }
    function increase() internal returns(uint256) {
      count ++;
      return count;
    }
}