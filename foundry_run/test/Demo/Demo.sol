// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Demo {
    uint256 count;
    uint256 private pk;

    constructor() {

    }
    function increase() internal returns(uint256) {
      count ++;
      return count;
    }

    function day(uint256 lastUpdateTime,uint256 amount) public returns(uint256) {
      uint256 rate = (lastUpdateTime - block.timestamp) * amount / 30 days;
      // if(rate >= 1 ) {
      //   // 超过30天还是按照 1 : 1 兑换
      //   rate = 1;
      // }
      return rate;
    }
}