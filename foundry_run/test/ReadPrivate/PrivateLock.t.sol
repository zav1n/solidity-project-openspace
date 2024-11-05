// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./PrivateLock.sol";

contract PrivateLockTest is Test {
    PrivateLock public defaultDemo;
    uint256 public blockTime;

    function setUp() public {
        blockTime = block.timestamp;
        defaultDemo = new PrivateLock();
    }

    function test_readLocks() public {
        uint256 locksSlot = 0; // `_locks` 数组的基础槽位置
        
        // 计算数组存储的起始位置
        bytes32 baseSlot = keccak256(abi.encode(locksSlot));
        
        for (uint256 i = 0; i < 11; i++) {
            // 每个结构体占用2个槽位，所以要乘以2
            uint256 structBaseSlot = uint256(baseSlot) + (i * 2);
            
            // 读取第一个槽位（包含user和startTime）
            bytes32 slot0Data = vm.load(address(defaultDemo), bytes32(structBaseSlot));
            
            // 解析user（低160位）和startTime（接下来的64位）
            address user = address(uint160(uint256(slot0Data)));
            uint64 startTime = uint64(uint256(slot0Data) >> 160);
            
            // 读取第二个槽位（amount）
            bytes32 slot1Data = vm.load(address(defaultDemo), bytes32(structBaseSlot + 1));
            uint256 amount = uint256(slot1Data);

            // 验证数据
            assertEq(user, address(uint160(i + 1)), string(abi.encodePacked("Invalid user for index ", vm.toString(i))));
            assertEq(amount, 1e18 * (i + 1), string(abi.encodePacked("Invalid amount for index ", vm.toString(i))));
            assertEq(startTime, uint64(blockTime * 2 - i), string(abi.encodePacked("Invalid startTime for index ", vm.toString(i))));

            // 输出验证信息
            console.log("Lock", i);
            console.log("User:", user);
            console.log("StartTime:", startTime);
            console.log("Amount:", amount);
            console.log("----------------");
        }
    }
}