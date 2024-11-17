// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "@src/W6D4_Compound/KKToken.sol";
import "@src/W6D4_Compound/StakePoolV2.sol";

contract StakePoolV2Test is Test {
  KKToken kkToken;
  StakingPoolV2 stakePool;

  Account public owner = makeAccount("owner");
  Account public alice = makeAccount("alice");
  function setUp() public {
      kkToken = new KKToken("KK", "KK");
      stakePool = new StakingPoolV2(address(kkToken));
  }
  function test() public {
    // 为alice提供 100 ETH
    vm.deal(alice.addr, 100 ether);

    vm.startPrank(alice.addr);
      stakePool.stake{value: 100 ether}();
      uint256 balance = stakePool.balanceOf(alice.addr);
      // 质押100 ETh
      (uint256 staked,,) = stakePool.stakes(alice.addr);
      assertEq(balance, staked);


      // 提取质押 50 ETH
      vm.roll(block.number + 100); // 区块高度: 101
      stakePool.unstake(50 ether);
      assertEq(alice.addr.balance, 50 ether);

      vm.roll(block.number + 100); // 区块高度: 201
      console.log("before claim token holding: ", kkToken.balanceOf(alice.addr));
      assertEq(0, kkToken.balanceOf(alice.addr));
      stakePool.claim();
      console.log("after claim ", kkToken.balanceOf(alice.addr));

      kkToken.balanceOf(alice.addr);
    vm.stopPrank();
  }
}
