// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title 访问控制合约示例
 * @dev 演示如何实现安全的访问控制机制
 */
contract AccessControl {
    // 角色定义
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    
    // 角色映射：角色 => 账户 => 是否拥有该角色
    mapping(bytes32 => mapping(address => bool)) private _roles;
    
    // 合约拥有者
    address private _owner;
    
    // 事件定义
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev 构造函数，设置合约拥有者并授予ADMIN角色
     */
    constructor() {
        _owner = msg.sender;
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @dev 检查调用者是否拥有特定角色的修饰器
     */
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "AccessControl: sender doesn't have role");
        _;
    }
    
    /**
     * @dev 检查调用者是否为合约拥有者的修饰器
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "AccessControl: sender is not the owner");
        _;
    }
    
    /**
     * @dev 检查账户是否拥有特定角色
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }
    
    /**
     * @dev 授予角色给账户（仅限管理员）
     */
    function grantRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }
    
    /**
     * @dev 撤销账户的角色（仅限管理员）
     */
    function revokeRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }
    
    /**
     * @dev 转移合约拥有权（仅限拥有者）
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "AccessControl: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    /**
     * @dev 获取当前合约拥有者
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    /**
     * @dev 内部函数：授予角色
     */
    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }
    
    /**
     * @dev 内部函数：撤销角色
     */
    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

/**
 * @title 使用访问控制的资金管理合约
 * @dev 演示如何在实际应用中使用访问控制
 */
contract FundManager {
    // 访问控制合约
    AccessControl private _accessControl;
    
    // 资金映射
    mapping(address => uint256) private _funds;
    
    // 总资金
    uint256 private _totalFunds;
    
    // 事件定义
    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);
    event EmergencyWithdrawal(address indexed admin, uint256 amount);
    
    /**
     * @dev 构造函数，设置访问控制合约
     */
    constructor(address accessControlAddress) {
        _accessControl = AccessControl(accessControlAddress);
    }
    
    /**
     * @dev 检查调用者是否拥有特定角色的修饰器
     */
    modifier onlyRole(bytes32 role) {
        require(_accessControl.hasRole(role, msg.sender), "FundManager: sender doesn't have role");
        _;
    }
    
    /**
     * @dev 存款函数（任何人都可以调用）
     */
    function deposit() external payable {
        _funds[msg.sender] += msg.value;
        _totalFunds += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev 提款函数（仅限用户角色）
     */
    function withdraw(uint256 amount) external onlyRole(_accessControl.USER_ROLE()) {
        require(_funds[msg.sender] >= amount, "FundManager: insufficient funds");
        _funds[msg.sender] -= amount;
        _totalFunds -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * @dev 紧急提款函数（仅限管理员角色）
     */
    function emergencyWithdraw(uint256 amount) external onlyRole(_accessControl.ADMIN_ROLE()) {
        require(_totalFunds >= amount, "FundManager: insufficient total funds");
        _totalFunds -= amount;
        payable(msg.sender).transfer(amount);
        emit EmergencyWithdrawal(msg.sender, amount);
    }
    
    /**
     * @dev 获取账户余额
     */
    function balanceOf(address account) external view returns (uint256) {
        return _funds[account];
    }
    
    /**
     * @dev 获取总资金
     */
    function totalFunds() external view returns (uint256) {
        return _totalFunds;
    }
}