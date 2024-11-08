// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/LinkedList/LinkBank.sol";

contract TokenFactoryTest is Test {
    LinkedBank bank;
    address constant GUARD = address(1);
    function setUp() public {
      // do nothing
      bank = new LinkedBank();
    }
    function test_deposit() public {
      address user1 = vm.randomAddress();
      address user2 = vm.randomAddress();
      address user3 = vm.randomAddress();
      address user4 = vm.randomAddress();
      address user5 = vm.randomAddress();
      address user6 = vm.randomAddress();
      address user7 = vm.randomAddress();
      address user8 = vm.randomAddress();
      address user9 = vm.randomAddress();
      address user10 = vm.randomAddress();

      vm.deal(user1, 10 ether);
      vm.deal(user2, 34 ether);
      vm.deal(user3, 31 ether);
      vm.deal(user4, 42 ether);
      vm.deal(user5, 23 ether);
      vm.deal(user6, 54 ether);
      vm.deal(user7, 22 ether);
      vm.deal(user8, 78 ether);
      vm.deal(user9, 39 ether);
      vm.deal(user10, 67 ether);

      vm.prank(user1);
      bank.deposit{ value: 10 ether }(GUARD, GUARD);
      bank.balanceOf(user1);

      vm.prank(user2);
      bank.deposit{ value: 34 ether }(GUARD, user2);

      vm.prank(user3);
      bank.deposit{ value: 31 ether }(user1, user3);

      vm.prank(user4);
      bank.deposit{value: 42 ether }(user2, user4);

      vm.prank(user5);
      bank.deposit{ value: 23 ether }(user1, user5);
    }
}