// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@src/RNT/RNT.sol";
import "@src/RNT/esRNT.sol";
import "@src/RNT/StakePool.sol";


contract StakePoolTest is Test {
  RNT public rntToken;
  esRNT public esrentToken;
  StakePool public stakePool;
  address owner;
  address alice;

  function setUp() public {
    owner = address(this);
    alice = makeAddr("alice");

    rntToken = new RNT();
    esrentToken = new esRNT(rntToken);
    stakePool = new StakePool(rntToken, esrentToken);
    esrentToken.transferOwnership(address(stakePool));

    rntToken.transfer(alice, 1000 ether);
  }

  function test_stake() public {
    vm.startPrank(alice);
      // a 用户把自己的token授权给StakePool
      rntToken.approve(address(stakePool), 1000 ether);

      // a 用户拿自己1000e去质押
      stakePool.stake(300 ether);

      // 检查质押结果
      (uint256 staked,,) = stakePool.stakes(alice);
      assertEq(staked, 300 ether);
      assertEq(rntToken.balanceOf(alice), 700 ether);

    vm.stopPrank();
  }

  function test_unstake() public {
    vm.startPrank(alice);
      rntToken.approve(address(stakePool), 1000 ether);

      stakePool.stake(300 ether);
      stakePool.unstake(120 ether);

      (uint256 staked,,) = stakePool.stakes(alice);
      assertEq(staked, 180 ether);
      assertEq(rntToken.balanceOf(alice), 820 ether);

    vm.stopPrank();
  }
  function test_claim() public {
    vm.startPrank(alice);
      // a 用户把自己的token授权给StakePool
      rntToken.approve(address(stakePool), 1000 ether);

      // a 用户拿自己1000e去质押
      stakePool.stake(100 ether);

      // 检查质押结果
      (uint256 staked,,) = stakePool.stakes(alice);
      assertEq(staked, 100 ether);

      vm.warp(block.timestamp + 16 days);

      stakePool.claim();

    vm.stopPrank();
  }

  function test_redeemEsRNT() public {
    vm.startPrank(alice);
      // a 用户把自己的token授权给StakePool
      rntToken.approve(address(stakePool), 1000 ether);

      // a 用户拿自己1000e去质押
      stakePool.stake(100 ether);

      // 检查质押结果
      (uint256 staked,,) = stakePool.stakes(alice);
      assertEq(staked, 100 ether);

      uint256 afterTime = block.timestamp + 28 days;
      vm.warp(afterTime);
      stakePool.claim();

      stakePool.redeemEsRNT();

      
    vm.stopPrank();
  }
}