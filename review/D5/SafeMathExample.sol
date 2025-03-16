// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMath库示例
 * @dev 演示整数溢出与下溢的防护方法
 */

// 在Solidity 0.8.0之前需要使用的SafeMath库
library SafeMath {
    /**
     * @dev 安全加法，防止溢出
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev 安全减法，防止下溢
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev 安全乘法，防止溢出
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev 安全除法，防止除零错误
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

/**
 * @title 0.8.0之前的合约示例
 * @dev 演示如何在Solidity 0.8.0之前使用SafeMath防止整数溢出
 */
contract Pre080Contract {
    // 使用SafeMath库
    using SafeMath for uint256;
    
    mapping(address => uint256) public balances;
    
    // 安全的存款函数
    function deposit(uint256 amount) external {
        // 使用SafeMath的add函数防止溢出
        balances[msg.sender] = balances[msg.sender].add(amount);
    }
    
    // 安全的转账函数
    function transfer(address to, uint256 amount) external {
        // 使用SafeMath的sub函数防止下溢
        balances[msg.sender] = balances[msg.sender].sub(amount);
        // 使用SafeMath的add函数防止溢出
        balances[to] = balances[to].add(amount);
    }
}

/**
 * @title 0.8.0及之后的合约示例
 * @dev 演示Solidity 0.8.0及之后版本内置的整数溢出检查
 */
contract Post080Contract {
    mapping(address => uint256) public balances;
    
    // 存款函数 - 0.8.0及之后版本自动检查溢出
    function deposit(uint256 amount) external {
        // 0.8.0及之后版本会自动检查溢出
        balances[msg.sender] += amount;
    }
    
    // 转账函数 - 0.8.0及之后版本自动检查下溢
    function transfer(address to, uint256 amount) external {
        // 0.8.0及之后版本会自动检查下溢
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    // 演示如何在0.8.0及之后版本中禁用溢出检查（不推荐）
    function unsafeAdd(uint256 a, uint256 b) external pure returns (uint256) {
        // 使用unchecked块禁用溢出检查
        unchecked {
            return a + b;
        }
    }
}

/**
 * @title 整数溢出测试合约
 * @dev 演示整数溢出与下溢的情况
 */
contract OverflowTest {
    // 测试加法溢出
    function testAddOverflow() external pure returns (uint8) {
        uint8 a = 255;
        uint8 b = 1;
        // 在0.8.0之前，这会导致溢出，结果为0
        // 在0.8.0及之后，这会抛出异常
        return a + b;
    }
    
    // 测试减法下溢
    function testSubUnderflow() external pure returns (uint8) {
        uint8 a = 0;
        uint8 b = 1;
        // 在0.8.0之前，这会导致下溢，结果为255
        // 在0.8.0及之后，这会抛出异常
        return a - b;
    }
    
    // 测试乘法溢出
    function testMulOverflow() external pure returns (uint8) {
        uint8 a = 100;
        uint8 b = 3;
        // 在0.8.0之前，这会导致溢出，结果为44 (300 % 256)
        // 在0.8.0及之后，这会抛出异常
        return a * b;
    }
    
    // 使用unchecked关键字禁用溢出检查
    function testUncheckedOverflow() external pure returns (uint8) {
        uint8 a = 255;
        uint8 b = 1;
        unchecked {
            // 即使在0.8.0及之后，这也会导致溢出，结果为0
            return a + b;
        }
    }
}