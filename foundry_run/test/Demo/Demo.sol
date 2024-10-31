// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Demo {
    uint256 count;
    uint256 private pk;
    function increase() internal returns(uint256) {
      count ++;
      return count;
    }
}