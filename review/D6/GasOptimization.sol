// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Gas优化示例
 * @dev 展示常见的Solidity gas优化技巧
 */
contract GasOptimization {
    // ================ 存储优化 ================
    
    // 未优化：使用多个bool变量
    bool public isPaused;
    bool public isUpgradeable;
    bool public isPublic;
    bool public isRestricted;
    
    // 优化：使用位图打包多个bool变量
    // 可以在一个uint8中存储8个bool标志
    uint8 private _flags;
    
    // 位图的位置常量
    uint8 private constant FLAG_IS_PAUSED = 1;      // 00000001
    uint8 private constant FLAG_IS_UPGRADEABLE = 2; // 00000010
    uint8 private constant FLAG_IS_PUBLIC = 4;      // 00000100
    uint8 private constant FLAG_IS_RESTRICTED = 8;  // 00001000
    
    // 设置标志
    function setFlag(uint8 flag, bool value) internal {
        if (value) {
            _flags |= flag; // 设置位
        } else {
            _flags &= ~flag; // 清除位
        }
    }
    
    // 读取标志
    function getFlag(uint8 flag) internal view returns (bool) {
        return (_flags & flag) != 0;
    }
    
    // ================ 变量打包 ================
    
    // 未优化：未考虑变量打包
    struct UserDataUnoptimized {
        uint256 id;        // 32字节
        uint8 age;         // 1字节，但占用一个完整插槽
        bool isActive;     // 1字节，但占用一个完整插槽
        address wallet;    // 20字节，但占用一个完整插槽
    } // 总共使用4个存储插槽
    
    // 优化：变量打包以减少存储插槽使用
    struct UserDataOptimized {
        uint256 id;        // 32字节
        uint8 age;         // 1字节
        bool isActive;     // 1字节
        address wallet;    // 20字节
    } // 总共使用2个存储插槽 (id在一个插槽，其余变量共享一个插槽)
    
    // ================ 循环优化 ================
    
    // 未优化：在循环中读取存储变量
    uint256[] private _data;
    
    function sumUnoptimized() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _data.length; i++) { // 每次迭代都会读取存储
            sum += _data[i];
        }
        return sum;
    }
    
    // 优化：将存储变量缓存到内存
    function sumOptimized() public view returns (uint256) {
        uint256[] memory data = _data; // 一次性将数组加载到内存
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) { // 从内存读取，更便宜
            sum += data[i];
        }
        return sum;
    }
    
    // ================ 函数优化 ================
    
    // 未优化：不必要的内部函数调用
    function processDataUnoptimized(uint256[] memory data) public pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < data.length; i++) {
            result += multiplyByTwo(data[i]); // 每次迭代都调用函数
        }
        return result;
    }
    
    function multiplyByTwo(uint256 value) internal pure returns (uint256) {
        return value * 2;
    }
    
    // 优化：内联简单操作
    function processDataOptimized(uint256[] memory data) public pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < data.length; i++) {
            result += data[i] * 2; // 直接内联操作，避免函数调用开销
        }
        return result;
    }
    
    // ================ 字符串优化 ================
    
    // 未优化：使用字符串
    string public constant UNOPTIMIZED_MESSAGE = "This is a message that will be stored as a string";
    
    // 优化：对于不需要人类可读性的数据，使用bytes32
    bytes32 public constant OPTIMIZED_MESSAGE = bytes32("This is a message stored as bytes32");
    
    // ================ 事件优化 ================
    
    // 未优化：所有参数都被索引
    event UnoptimizedEvent(address indexed user, uint256 indexed amount, string indexed description);
    
    // 优化：只索引需要搜索的参数（最多3个indexed）
    event OptimizedEvent(address indexed user, uint256 amount, string description);
    
    // ================ 条件优化 ================
    
    // 未优化：复杂条件判断
    function checkConditionsUnoptimized(uint256 value) public pure returns (bool) {
        // 复杂条件会导致更多的操作码
        if (value > 100 && value < 200 || value > 300 && value < 400 || value == 500) {
            return true;
        }
        return false;
    }
    
    // 优化：简化条件逻辑
    function checkConditionsOptimized(uint256 value) public pure returns (bool) {
        // 提前返回减少操作码
        if (value == 500) return true;
        if (value > 100 && value < 200) return true;
        if (value > 300 && value < 400) return true;
        return false;
    }
    
    // ================ 整数类型优化 ================
    
    // 未优化：使用uint256存储小数值
    mapping(address => uint256) private _smallValues;
    
    // 优化：对于小数值使用较小的整数类型（在结构体和数组中有效）
    struct OptimizedStruct {
        uint8 smallValue; // 对于0-255的值
        uint16 mediumValue; // 对于0-65535的值
        uint32 largerValue; // 对于更大但仍有限的值
    }
    
    // ================ 映射 vs 数组 ================
    
    // 未优化：使用数组存储可以通过键查找的数据
    struct User {
        address userAddress;
        uint256 balance;
    }
    User[] private _users;
    
    // 查找用户 - O(n)复杂度
    function findUserUnoptimized(address userAddress) public view returns (uint256) {
        for (uint256 i = 0; i < _users.length; i++) {
            if (_users[i].userAddress == userAddress) {
                return _users[i].balance;
            }
        }
        return 0;
    }
    
    // 优化：使用映射进行O(1)查找
    mapping(address => uint256) private _userBalances;
    
    function findUserOptimized(address userAddress) public view returns (uint256) {
        return _userBalances[userAddress]; // O(1)查找
    }
    
    // ================ 实用优化技巧 ================
    
    // 1. 使用unchecked块减少Solidity 0.8.0+中的溢出检查
    function incrementUnchecked(uint256 x) public pure returns (uint256) {
        // 当你确定不会溢出时，使用unchecked可以节省gas
        unchecked {
            return x + 1;
        }
    }
    
    // 2. 短路条件评估
    function shortCircuitExample(uint256 a, uint256 b) public pure returns (bool) {
        // 将更可能为false的条件放在前面
        // 将更便宜的条件检查放在前面
        return a == 0 && complexOperation(b);
    }
    
    function complexOperation(uint256 x) internal pure returns (bool) {
        // 假设这是一个复杂的操作
        return x % 42 == 0;
    }
    
    // 3. 使用calldata而非memory用于外部函数的只读数组/字符串参数
    function processCalldataArray(uint256[] calldata data) external pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        return sum;
    }
    
    // 4. 固定大小的数组比动态数组更高效
    uint256[10] private _fixedArray; // 比动态数组更高效
    
    // 5. 使用库进行复杂操作
    // 使用库可以重用代码并减少部署成本
    
    // 6. 避免在循环中修改存储变量
    function updateValuesUnoptimized(uint256[] memory newValues) public {
        for (uint256 i = 0; i < newValues.length; i++) {
            _data[i] = newValues[i]; // 每次迭代都写入存储
        }
    }
    
    function updateValuesOptimized(uint256[] memory newValues) public {
        uint256[] storage data = _data; // 获取存储引用
        for (uint256 i = 0; i < newValues.length; i++) {
            data[i] = newValues[i]; // 使用局部变量引用存储
        }
    }
}