### 常见安全问题

<img width="70%" src="https://github.com/user-attachments/assets/efb4537f-c6bd-4968-91e4-46fffdcffedc">

<img width="70%" src="[https://github.com/user-attachments/assets/efb4537f-c6bd-4968-91e4-46fffdcffedc](https://github.com/user-attachments/assets/4e3222fc-8805-4981-a216-7823d385d81f)">

### 常见漏洞
- 重入攻击
调⽤外部函数时，要时刻注意重⼊问题

<img width="50%" src="https://github.com/user-attachments/assets/15e5c93d-1215-46a7-8a51-62b6526b2958">

解决办法: 

先检查 - 再修改 - 最后交互（checks-effect-interaction）

重⼊锁控制

引⼊的新操作码，引⼊了⼀个新存储空间（瞬时存储），读写更便宜, 对该存储的修改仅在⼀个交易内有效

> 此外还有一下问题

- Dos 拒绝服务
- 签名重用
- 溢出（Solidity < 0.8）、 精度损失
- 合约账户控制

### 找出一下代码问题之处

1. 第一题

```solidity
function withdraw() public {
    (bool success, ) = msg.sender.call{value: deposits[msg.sender]}("");
    deposits[msg.sender] = 0;
    require(success, "Failed to send Ether");
}
```

解答: 这是一个重入攻击, msg.sender可能是合约, 会调到fallback或者receive, 里面可以再调用到deposits
解决办法一:
先判断deposits[msg.sender]是否有钱再转

解决办法二:
lock = 1
_;
lock = 0

2. 第二题 

```solidity
function enter() public {
    // Check for duplicate entrants
    for (uint256 i; i < entrants.length; i++) {
        if (entrants[i] == msg.sender) {
            revert("You've already entered!");
        }
    }
    entrants.push(msg.sender);
}
```

解答: 遍历问题

3. 第三题

```solidity
pragma solidity^0.8.0;
contract bank {
  uint256 public totalDeposits;
  mapping(address => uint256) public deposits;
  function deposit() external payable {
      deposits[msg.sender] += msg.value;
      totalDeposits += msg.value;
  }
  function withdraw() external {
    assert(address(this).balance == totalDeposits);
    uint256 amount = deposits[msg.sender];
    totalDeposits -= amount;
    deposits[msg.sender] = 0;
    payable(msg.sender).transfer(amount);  // 0
  }
}

```

解答: 合约有可能销毁或者挖矿节点可以换掉地址


参考资料:

(防止重入攻击的 4 种方法)[https://learnblockchain.cn/article/4118]
