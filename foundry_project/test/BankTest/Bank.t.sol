// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { Bank } from "../../src/Bank/Bank.sol";


contract BankTest is Test {
    Bank public bank;

    function setUp() public {
        bank = new Bank();
    }

    function test_depositETH() public {
        address user = address(this); // 当前测试用户
        uint256 depositAmount = 1 ether;

        // 设置期望的事件和对应参数
        // vm.expectEmit(true, true, false, true); // 设置捕获事件的参数
        // emit Deposit(user, depositAmount);      // 期望的事件数据

        // 调用 depositETH 函数
        bank.depositETH{value: depositAmount}();

        console.log('balanceOf user', bank.balanceOf(user));
        // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
        assertEq(bank.balanceOf(user), depositAmount);
    }
}

/**
vm.deal
vm.prank



总结: 
1. 文件名规范
为了测试MyContract.sol，测试文件应该是MyContract.t.sol。 为了测试 MyScript.s.sol，测试文件应该是 MyScript.t.sol。
如果合约很大并且您想将其拆分为多个文件，请将它们按逻辑分组，如 MyContract.owner.t.sol、MyContract.deposits.t.sol 等。

2. 永远不要在 setUp 函数中做出断言，如果您需要确保 setUp 函数执行预期的操作，请使用像 test_SetUpState() 这样的专用测试。 有关原因的更多信息，请参见 foundry-rs/foundry#1291

3. 每个被测试的 internal 函数都应该通过一个名称遵循 exposed_<function_name> 模式的外部函数公开。 例如：


// file: src/MyContract.sol
contract MyContract {
  function myInternalMethod() internal returns (uint) {
    return 42;
  }
}

// file: test/MyContract.t.sol
import {MyContract} from "src/MyContract.sol";

contract MyContractHarness is MyContract {
  // Deploy this contract then cll this method to test `myInternalMethod`.
  function exposed_myInternalMethod() external returns (uint) {
    return myInternalMethod();
  }
}
 */