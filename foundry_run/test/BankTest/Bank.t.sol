// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { Bank, IBank } from "@src/Bank/Bank.sol";


contract BankTest is Test {
    Bank public bank;
    function setUp() public {
        bank = new Bank();
    }

    function test_deposit() public {
        address user = address(this); // 当前测试用户
        uint256 depositAmount = 1 ether;
        
        vm.startPrank(user);
        /**
          Q: 如何理解expectEmit‘
          Q: 为什么不能放在 bank.depositETH 后面
          因为需要先埋点事件, 才能在出发事件的时候去执行埋点
          报错信息: [FAIL: expected an emit, but no logs were emitted afterwards. you might have mismatched events or not enough events were emitted]
        */

        vm.expectEmit(true, true, false, true); // 设置捕获事件的参数
        emit IBank.Deposit(user, depositAmount);      // 期望的事件数据

        // 调用 depositETH 函数
        bank.deposit{value: depositAmount}();

        vm.stopPrank();
        
        // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
        assertEq(bank.balanceOf(user), depositAmount);
    }
}
