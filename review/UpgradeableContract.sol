// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title 自定义可升级合约系统
 * @dev 本文件展示了如何不使用OpenZeppelin库实现可升级合约
 */

/**
 * @dev 存储合约 - 用于存储代理合约的状态变量
 * 所有的状态变量都应该在这里定义，以确保存储布局一致性
 */
contract Storage {
    // 存储槽0: 管理员地址
    address private _admin;
    
    // 存储槽1: 实现合约地址
    address private _implementation;
    
    // 存储槽2: 初始化状态
    bool private _initialized;
    
    // 存储槽3及以后: 业务逻辑相关的状态变量
    uint256 private _value;
    mapping(address => uint256) private _balances;
    
    // 事件
    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
}

/**
 * @dev 代理合约 - 负责委托调用到实现合约
 * 继承自Storage以确保存储布局一致
 */
contract Proxy is Storage {
    // 构造函数 - 设置初始管理员
    constructor() {
        _setAdmin(msg.sender);
    }
    
    // 回退函数 - 将所有调用委托给实现合约
    fallback() external payable {
        _delegate(_getImplementation());
    }
    
    // 接收函数 - 处理纯ETH转账
    receive() external payable {
        _delegate(_getImplementation());
    }
    
    /**
     * @dev 升级实现合约
     * @param newImplementation 新的实现合约地址
     */
    function upgradeTo(address newImplementation) external {
        require(msg.sender == _getAdmin(), "Proxy: caller is not admin");
        require(newImplementation != address(0), "Proxy: new implementation is zero address");
        _setImplementation(newImplementation);
    }
    
    /**
     * @dev 更改管理员
     * @param newAdmin 新的管理员地址
     */
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _getAdmin(), "Proxy: caller is not admin");
        require(newAdmin != address(0), "Proxy: new admin is zero address");
        address oldAdmin = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
    }
    
    /**
     * @dev 获取当前管理员
     */
    function admin() external view returns (address) {
        return _getAdmin();
    }
    
    /**
     * @dev 获取当前实现合约地址
     */
    function implementation() external view returns (address) {
        return _getImplementation();
    }
    
    /**
     * @dev 内部函数：获取管理员地址
     */
    function _getAdmin() internal view returns (address) {
        return _admin;
    }
    
    /**
     * @dev 内部函数：设置管理员地址
     */
    function _setAdmin(address newAdmin) internal {
        _admin = newAdmin;
    }
    
    /**
     * @dev 内部函数：获取实现合约地址
     */
    function _getImplementation() internal view returns (address) {
        return _implementation;
    }
    
    /**
     * @dev 内部函数：设置实现合约地址
     */
    function _setImplementation(address newImplementation) internal {
        _implementation = newImplementation;
        emit Upgraded(newImplementation);
    }
    
    /**
     * @dev 内部函数：委托调用到实现合约
     */
    function _delegate(address implementation) internal {
        // 复制调用数据
        assembly {
            // 复制msg.data
            calldatacopy(0, 0, calldatasize())
            
            // 执行delegatecall
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            
            // 复制返回数据
            returndatacopy(0, 0, returndatasize())
            
            // 根据调用结果返回或回滚
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

/**
 * @dev 逻辑合约V1 - 包含业务逻辑
 * 继承自Storage以确保存储布局一致
 */
contract LogicV1 is Storage {
    /**
     * @dev 初始化函数 - 替代构造函数
     * 确保只能被调用一次
     */
    function initialize() external {
        require(!_initialized, "Contract already initialized");
        _initialized = true;
        _value = 100; // 初始值
    }
    
    /**
     * @dev 设置值
     * @param newValue 新的值
     */
    function setValue(uint256 newValue) external {
        _value = newValue;
    }
    
    /**
     * @dev 获取值
     */
    function getValue() external view returns (uint256) {
        return _value;
    }
    
    /**
     * @dev 存款
     */
    function deposit() external payable {
        _balances[msg.sender] += msg.value;
    }
    
    /**
     * @dev 获取余额
     */
    function getBalance() external view returns (uint256) {
        return _balances[msg.sender];
    }
    
    /**
     * @dev 获取合约版本
     */
    function getVersion() external pure returns (string memory) {
        return "V1";
    }
}

/**
 * @dev 逻辑合约V2 - 包含更新的业务逻辑
 * 继承自Storage以确保存储布局一致
 */
contract LogicV2 is Storage {
    /**
     * @dev 初始化函数 - 替代构造函数
     * 确保只能被调用一次
     */
    function initialize() external {
        require(!_initialized, "Contract already initialized");
        _initialized = true;
        _value = 200; // 初始值更新为200
    }
    
    /**
     * @dev 设置值
     * @param newValue 新的值
     */
    function setValue(uint256 newValue) external {
        require(newValue > 0, "Value must be greater than 0"); // 新增验证
        _value = newValue;
    }
    
    /**
     * @dev 获取值
     */
    function getValue() external view returns (uint256) {
        return _value;
    }
    
    /**
     * @dev 存款
     */
    function deposit() external payable {
        _balances[msg.sender] += msg.value;
    }
    
    /**
     * @dev 获取余额
     */
    function getBalance() external view returns (uint256) {
        return _balances[msg.sender];
    }
    
    /**
     * @dev 提款 - 新增功能
     * @param amount 提款金额
     */
    function withdraw(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
    /**
     * @dev 获取合约版本
     */
    function getVersion() external pure returns (string memory) {
        return "V2";
    }
}

/**
 * @title 可升级合约使用示例
 * @dev 展示如何部署和使用可升级合约系统
 */
contract UpgradeableContractExample {
    /**
     * @dev 部署可升级合约系统的步骤：
     * 1. 部署LogicV1合约
     * 2. 部署Proxy合约
     * 3. 通过Proxy调用LogicV1的initialize函数
     * 4. 使用Proxy地址与LogicV1的ABI进行交互
     * 
     * 升级到V2的步骤：
     * 1. 部署LogicV2合约
     * 2. 调用Proxy的upgradeTo函数，传入LogicV2的地址
     * 3. 使用Proxy地址与LogicV2的ABI进行交互
     */
    
    /**
     * @dev 以下是使用示例代码（在实际部署中不需要）
     */
    function deployAndUpgrade() external {
        // 这只是示例代码，实际使用时应该在外部脚本中执行这些步骤
        
        // 1. 部署LogicV1
        LogicV1 logicV1 = new LogicV1();
        
        // 2. 部署Proxy
        Proxy proxy = new Proxy();
        
        // 3. 升级Proxy指向LogicV1
        proxy.upgradeTo(address(logicV1));
        
        // 4. 初始化LogicV1
        LogicV1(address(proxy)).initialize();
        
        // 5. 使用LogicV1的功能
        LogicV1(address(proxy)).setValue(150);
        uint256 value = LogicV1(address(proxy)).getValue(); // 应该返回150
        
        // 6. 部署LogicV2
        LogicV2 logicV2 = new LogicV2();
        
        // 7. 升级Proxy指向LogicV2
        proxy.upgradeTo(address(logicV2));
        
        // 8. 使用LogicV2的新功能
        LogicV2(address(proxy)).deposit{value: 1 ether}();
        LogicV2(address(proxy)).withdraw(0.5 ether);
        
        // 9. 检查版本
        string memory version = LogicV2(address(proxy)).getVersion(); // 应该返回"V2"
    }
}