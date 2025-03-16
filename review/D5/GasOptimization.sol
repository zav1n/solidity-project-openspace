// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Gas优化示例合约
 * @dev 演示各种Gas优化技巧
 */
contract GasOptimization {
    // ==================== 存储优化 ====================
    
    /**
     * @dev 未优化的结构体 - 存储布局不佳
     * 总计使用3个存储槽（每个槽32字节）
     */
    struct UnoptimizedStruct {
        uint8 a;      // 1字节，但占用一个完整的槽
        uint256 b;    // 32字节，占用一个完整的槽
        uint8 c;      // 1字节，但占用一个完整的槽
    }
    
    /**
     * @dev 优化后的结构体 - 变量打包
     * 总计使用2个存储槽
     */
    struct OptimizedStruct {
        uint8 a;      // 1字节
        uint8 c;      // 1字节，与a打包在同一个槽中
        uint256 b;    // 32字节，占用一个完整的槽
    }
    
    // 未优化的映射
    mapping(address => UnoptimizedStruct) public unoptimizedData;
    
    // 优化后的映射
    mapping(address => OptimizedStruct) public optimizedData;
    
    /**
     * @dev 使用位图存储多个布尔值
     * 一个uint8可以存储8个布尔标志
     */
    uint8 private _booleanFlags;
    
    // 位图中的位置常量
    uint8 private constant FLAG_IS_ACTIVE = 1;      // 00000001
    uint8 private constant FLAG_IS_PAUSED = 2;      // 00000010
    uint8 private constant FLAG_IS_SPECIAL = 4;     // 00000100
    uint8 private constant FLAG_HAS_VOTED = 8;      // 00001000
    uint8 private constant FLAG_IS_WHITELISTED = 16; // 00010000
    
    /**
     * @dev 设置布尔标志
     */
    function setFlag(uint8 flag, bool value) external {
        if (value) {
            _booleanFlags |= flag; // 设置位
        } else {
            _booleanFlags &= ~flag; // 清除位
        }
    }
    
    /**
     * @dev 检查布尔标志
     */
    function checkFlag(uint8 flag) external view returns (bool) {
        return (_booleanFlags & flag) == flag;
    }
    
    // ==================== 循环优化 ====================
    
    /**
     * @dev 未优化的循环 - 在循环内进行计算
     */
    function unoptimizedLoop(uint256[] memory data) external pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i] * 2; // 在循环内进行计算
        }
        return sum;
    }
    
    /**
     * @dev 优化后的循环 - 减少循环内计算
     */
    function optimizedLoop(uint256[] memory data) external pure returns (uint256) {
        uint256 sum = 0;
        uint256 length = data.length; // 缓存数组长度
        for (uint256 i = 0; i < length; i++) {
            sum += data[i];
        }
        return sum * 2; // 将乘法操作移到循环外
    }
    
    /**
     * @dev 未优化的数组增长
     */
    function unoptimizedArrayGrowth(uint256 size) external pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](0);
        for (uint256 i = 0; i < size; i++) {
            // 注意：这在内存数组上不可行，但在存储数组上会非常消耗gas
            // 这里仅作为示例
            // 如果是存储数组，每次push都会导致数组重新分配空间
            // result.push(i);
        }
        return result;
    }
    
    /**
     * @dev 优化后的数组操作 - 预分配空间
     */
    function optimizedArrayOperation(uint256 size) external pure returns (uint256[] memory) {
        // 预先分配正确大小的数组
        uint256[] memory result = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            result[i] = i;
        }
        return result;
    }
    
    // ==================== 批量操作优化 ====================
    
    /**
     * @dev 单个转账操作
     */
    function individualTransfers(address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            // 在实际合约中，这里会是一个转账操作
            // 每次转账都会产生一次外部调用的gas成本
            // payable(recipients[i]).transfer(amounts[i]);
        }
    }
    
    /**
     * @dev 批量转账操作
     * 在实际应用中，可以使用批量转账合约或ERC20的批量转账功能
     */
    function batchTransfer(address[] memory recipients, uint256 amount) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            // 在实际合约中，这里会是一个转账操作
            // 使用相同的金额可以简化逻辑
            // payable(recipients[i]).transfer(amount);
        }
    }
    
    // ==================== 位运算优化 ====================
    
    /**
     * @dev 使用算术运算计算2的幂
     */
    function powerOfTwoArithmetic(uint8 n) external pure returns (uint256) {
        return 2 ** n; // 使用幂运算
    }
    
    /**
     * @dev 使用位运算计算2的幂（更高效）
     */
    function powerOfTwoBitwise(uint8 n) external pure returns (uint256) {
        return 1 << n; // 使用左移运算
    }
    
    /**
     * @dev 使用算术运算检查奇偶性
     */
    function isEvenArithmetic(uint256 n) external pure returns (bool) {
        return n % 2 == 0; // 使用模运算
    }
    
    /**
     * @dev 使用位运算检查奇偶性（更高效）
     */
    function isEvenBitwise(uint256 n) external pure returns (bool) {
        return (n & 1) == 0; // 使用位与运算
    }
    
    /**
     * @dev 使用算术运算计算除以2
     */
    function divideByTwoArithmetic(uint256 n) external pure returns (uint256) {
        return n / 2; // 使用除法运算
    }
    
    /**
     * @dev 使用位运算计算除以2（更高效）
     */
    function divideByTwoBitwise(uint256 n) external pure returns (uint256) {
        return n >> 1; // 使用右移运算
    }
}