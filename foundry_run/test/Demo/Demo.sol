// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/math/Math.sol";
contract Demo {
  using Math for uint256;
    uint256 count;
    uint256 private pk;

    constructor() {

    }
    function increase() internal returns(uint256) {
      count ++;
      return count;
    }

    function day() public returns(uint256) {

      return 1;
    }
}