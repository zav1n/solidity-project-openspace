## 理论题
### 1. 数据类型与变量
问题 ：解释Solidity中的值类型和引用类型的区别，并各举两个例子。
gas费用, 引用类型可以节省gas费用, 不会复制或者遍历大量数据
```solidity
// 值类型
uint256 num = 1;
address addr = 0x123;
bytes32 data = "new word";
bool isActive = false;
enum Status { Pedding, Active, Closed } 


// 引用类型
uint[] memory numbers = new uint[](2)
numbers[0] = 1;

mapping(address => uint) public balances;
balances[msg.sender];

struct Person {
  string name;
  uint age;
}
Person memory mike = Persion(Alice", 25)
Person memory onePeople = mike
onePeople.age = 26
```

### 2. 函数修饰符
问题 ：解释 view 、 pure 和 payable 修饰符的作用和区别。
view 只读不能写, 不会消耗gas费用, 适用于查询, 例如查询余额, 状态
pure 不能读写, 不会消耗gas, 适用于纯计算, 格式转换
payable 允许函数接收以太币, 没有这个修饰符的函数会导致交易失败
payable 可以访问msg.value获取发送以太币的数量, 适用于接收以太币

### 3. 可见性
问题 ：比较 external 和 public 函数的区别，在什么情况下应该选择使用 external 而非 public ？

external 只能从合约外部调用（除非使用this.function()语法）, 不能被合约内部的其他函数调用, 参数直接从calldata取, 对于大型数组等引用类型参数更省gas

public 内部外部都可以调用, 但是因为参数会复制到内存中, 导致gas费消耗会增加



### 4. Gas优化
问题 ：列举三种在Solidity中优化Gas使用的方法(尽量列举多点)。
1. 插槽的优化, 例如
```solidity
uint160 a;
address b;
bytes32 c;
uint96 d;

// 改变插槽顺序, 因为一个插槽占据32个字节(256位), 因此uint160和uint96可以顺位
bytes32 c;
uint160 a;
uint96 d;
address b;
```

2. 压缩字节(变量)

3. 尽量不在合约里面遍历和循环

4. 使用 calldata代替memory

5. 减少storage的读写

6. 使用不可变immutable和常量constants

7. 优化函数可见性, 优先使用private和internal

8. 优化逻辑, 使用逻辑运算符 && , || 进行判断

9. 多个相同返回判断使用modify修饰器, 虽然不一定能省gas费, 至少可以减少代码重复, 提高可读性

10. 事件只记录必要数据

11. 使用indexed索引提升查询效率

12. 使用继承和libary

13. 使用gasleft() 检查gas消耗并且做出对应优化

14. 避免动态数组长度变化

### 5. 重入攻击
问题 ：什么是重入攻击？如何在合约中防止重入攻击？
利用回调函数再次进入目标合约的同一函数, 从而导致执行敏感动作, 如提款
一般攻击者会利用receive或fallback, 利用更新合约状态前又一次出发
1. 使用OpenZeppelin的ReentrancyGuard

2. 使用重入锁 ReentrancyGuard

3. 遵循检查-效果-交互模式

## 实践题
### 1. 基础合约实现
问题 ：编写一个简单的银行合约，包含存款、取款功能，并实现防重入攻击的保护措施。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint256) private balances;
    bool private locked;
    
    // 防重入锁
    modifier noReentrancy() {
        require(!locked, "重入攻击保护：禁止重入");
        locked = true;
        _;
        locked = false;
    }
    
    // 存款函数
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    // 查询余额函数 - 使用view修饰符
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    // 取款函数 - 使用防重入保护
    function withdraw(uint256 amount) external noReentrancy {
        require(balances[msg.sender] >= amount, "余额不足");
        
        // 检查-效果-交互模式
        // 1. 检查条件
        // 2. 更新状态
        balances[msg.sender] -= amount;
        
        // 3. 交互（发送以太币）
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "转账失败");
    }
    
    // 查询合约余额 - 仅供测试使用
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
 ```
```

### 2. 事件与日志实现
问题 ：修改上面的银行合约，添加适当的事件记录存款和取款操作。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BankWithEvents {
    mapping(address => uint256) private balances;
    bool private locked;
    
    // 定义事件
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    
    // 防重入锁
    modifier noReentrancy() {
        require(!locked, "重入攻击保护：禁止重入");
        locked = true;
        _;
        locked = false;
    }
    
    // 存款函数
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        
        // 触发存款事件
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    // 查询余额函数
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    // 取款函数 - 使用防重入保护
    function withdraw(uint256 amount) external noReentrancy {
        require(balances[msg.sender] >= amount, "余额不足");
        
        // 检查-效果-交互模式
        balances[msg.sender] -= amount;
        
        // 触发取款事件
        emit Withdrawal(msg.sender, amount, block.timestamp);
        
        // 发送以太币
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "转账失败");
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
 ```
```

### 3. 整数溢出/下溢保护
问题 ：编写一个简单的代币合约，实现铸造和转账功能，并确保防止整数溢出/下溢。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeToken {
    string public name = "SafeToken";
    string public symbol = "STK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "只有合约拥有者可以调用此函数");
        _;
    }
    
    // 铸造新代币 - 仅合约拥有者可调用
    function mint(address to, uint256 amount) external onlyOwner {
        // Solidity 0.8.0+ 已内置整数溢出检查，无需额外SafeMath
        totalSupply += amount;
        balances[to] += amount;
        
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }
    
    // 转账函数
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "不能转账到零地址");
        require(balances[msg.sender] >= amount, "余额不足");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    // 查询余额
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    // 授权其他地址代表发送者转账
    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    // 查询授权额度
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
    
    // 代表其他地址转账
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(from != address(0), "不能从零地址转账");
        require(to != address(0), "不能转账到零地址");
        require(balances[from] >= amount, "余额不足");
        require(allowances[from][msg.sender] >= amount, "授权额度不足");
        
        allowances[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}
 ```
```

## 进阶问题
1. 解释"检查-效果-交互"模式，为什么它对于防止重入攻击很重要？
2. 在Solidity 0.8.0版本之前和之后，处理整数溢出/下溢的方式有什么不同？
3. 如何使用Hardhat部署上述合约到测试网，并验证其功能？
这些题目涵盖了第一天学习内容中的核心概念。通过实践这些题目，您可以巩固Solidity基础知识，并为后续学习打下坚实基础。如果您需要任何解答或进一步的解释，请随时提问！