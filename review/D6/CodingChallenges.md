# Web3编码挑战集合

## 1. Solidity编码挑战

### 1.1 智能合约漏洞修复

#### 挑战1: 修复重入攻击漏洞

```solidity
// 有漏洞的合约
contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] = 0;
    }
}
```

**任务**: 修复上述合约中的重入攻击漏洞，确保资金安全。

#### 挑战2: 实现安全的代理合约

```solidity
// 不完整的代理合约
contract Proxy {
    address public implementation;
    address public admin;
    
    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }
    
    function upgrade(address newImplementation) external {
        // 缺少访问控制
        implementation = newImplementation;
    }
    
    fallback() external payable {
        // 缺少委托调用逻辑
    }
}
```

**任务**: 完善上述代理合约，添加适当的访问控制和委托调用逻辑，实现安全的合约升级机制。

### 1.2 DeFi算法实现

#### 挑战1: 实现AMM价格计算

**任务**: 实现一个函数，计算恒定乘积自动做市商(x * y = k)中的交易输出金额。

```solidity
// 待实现函数
function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256) {
    // 实现计算逻辑
    // 考虑0.3%的交易手续费
}
```

#### 挑战2: 实现借贷利率模型

**任务**: 实现一个动态利率模型，根据资金池利用率计算借款利率。

```solidity
// 待实现函数
function calculateBorrowRate(uint256 totalBorrows, uint256 totalLiquidity) external pure returns (uint256) {
    // 实现计算逻辑
    // 基础利率 + 利用率 * 斜率
    // 当利用率超过80%时，使用更高的斜率
}
```

### 1.3 Gas优化挑战

#### 挑战1: 优化存储布局

```solidity
// 未优化的合约
contract UnoptimizedStorage {
    bool public isPaused;
    uint256 public totalSupply;
    bool public isUpgradeable;
    address public owner;
    bool public isInitialized;
    uint8 public decimals;
}
```

**任务**: 重新组织上述合约的存储布局，以最小化gas消耗。

#### 挑战2: 优化循环操作

```solidity
// 未优化的函数
function sumArray(uint256[] storage data) external view returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < data.length; i++) {
        sum += data[i];
    }
    return sum;
}
```

**任务**: 优化上述函数，减少gas消耗。

## 2. Web3前端编码挑战

### 2.1 钱包集成

#### 挑战1: 实现多钱包连接

**任务**: 实现一个React组件，支持连接MetaMask、WalletConnect和Coinbase Wallet。

```typescript
// 待实现组件
import React from 'react';

const WalletConnector: React.FC = () => {
  // 实现钱包连接逻辑
  // 支持至少三种钱包
  
  return (
    <div>
      {/* 实现UI */}
    </div>
  );
};

export default WalletConnector;
```

#### 挑战2: 实现链切换功能

**任务**: 实现一个函数，检测当前链ID并提示用户切换到支持的网络。

```typescript
// 待实现函数
async function ensureCorrectChain(provider: any, supportedChainIds: number[]) {
  // 实现链检测和切换逻辑
}
```

### 2.2 合约交互

#### 挑战1: 实现ERC20代币转账

**任务**: 实现一个组件，允许用户转账ERC20代币并显示交易状态。

```typescript
// 待实现组件
import React from 'react';

interface TokenTransferProps {
  tokenAddress: string;
  tokenDecimals: number;
}

const TokenTransfer: React.FC<TokenTransferProps> = ({ tokenAddress, tokenDecimals }) => {
  // 实现代币转账逻辑
  
  return (
    <div>
      {/* 实现UI */}
    </div>
  );
};

export default TokenTransfer;
```

#### 挑战2: 实现NFT铸造功能

**任务**: 实现一个组件，允许用户铸造NFT并显示铸造状态。

```typescript
// 待实现组件
import React from 'react';

interface NFTMinterProps {
  contractAddress: string;
}

const NFTMinter: React.FC<NFTMinterProps> = ({ contractAddress }) => {
  // 实现NFT铸造逻辑
  
  return (
    <div>
      {/* 实现UI */}
    </div>
  );
};

export default NFTMinter;
```

### 2.3 数据处理

#### 挑战1: 实现TheGraph查询

**任务**: 实现一个Hook，从TheGraph查询用户的交易历史。

```typescript
// 待实现Hook
import { useState, useEffect } from 'react';

function useTransactionHistory(userAddress: string, subgraphUrl: string) {
  // 实现查询逻辑
  
  return {
    // 返回数据和状态
  };
}

export default useTransactionHistory;
```

#### 挑战2: 实现IPFS元数据加载

**任务**: 实现一个函数，从IPFS加载NFT元数据并处理错误情况。

```typescript
// 待实现函数
async function loadIPFSMetadata(ipfsHash: string) {
  // 实现IPFS加载逻辑
  // 处理超时和错误
}
```

## 3. 全栈DApp挑战

### 3.1 简易NFT市场

**任务**: 实现一个简单的NFT市场，包括以下功能：
- 智能合约：NFT铸造、上架、购买
- 前端：展示NFT、连接钱包、执行交易

### 3.2 DAO投票系统

**任务**: 实现一个简单的DAO投票系统，包括以下功能：
- 智能合约：提案创建、投票、执行
- 前端：提案列表、投票界面、投票结果展示

### 3.3 DeFi收益聚合器

**任务**: 实现一个简单的收益聚合器，包括以下功能：
- 智能合约：存款、提款、收益分配
- 前端：显示APY、存款界面、收益追踪

## 4. 面试准备策略

### 4.1 刷题平台推荐

1. **CryptoZombies**
   - 完成高级课程，特别是DeFi和NFT相关内容
   - 实践课程中的安全最佳实践

2. **Ethernaut**
   - 完成所有挑战，理解每个漏洞的原理
   - 尝试编写自己的解决方案变体

3. **QuillAudits CTF**
   - 参与安全挑战，提高漏洞识别能力
   - 分析真实世界的漏洞案例

4. **Buildspace**
   - 完成Web3项目构建教程
   - 基于教程扩展自己的项目

### 4.2 面试准备清单

1. **基础知识**
   - 复习Solidity基本语法和特性
   - 理解EVM工作原理
   - 掌握常见设计模式

2. **安全知识**
   - 熟悉OWASP Top 10 for Smart Contracts
   - 理解常见攻击向量
   - 掌握安全开发最佳实践

3. **工具熟练度**
   - Hardhat/Truffle开发环境
   - Ethers.js/Web3.js库
   - React和TypeScript

4. **项目准备**
   - 准备2-3个可以深入讨论的项目
   - 能够解释技术选择和架构决策
   - 准备项目中遇到的挑战和解决方案

### 4.3 模拟面试问题

1. **技术问题**
   - 解释ERC20和ERC721标准的区别
   - 如何防止闪电贷攻击？
   - 解释代理合约的工作原理

2. **设计问题**
   - 如何设计一个gas高效的NFT市场？
   - 如何实现跨链资产桥？
   - 如何设计一个可升级且安全的DeFi协议？

3. **问题解决**
   - 分析给定合约中的漏洞
   - 优化给定函数的gas消耗
   - 实现特定的DeFi算法

## 5. 资源推荐

### 5.1 学习资源

1. **文档**
   - [Solidity官方文档](https://docs.soliditylang.org/)
   - [Ethers.js文档](https://docs.ethers.io/)
   - [OpenZeppelin文档](https://docs.openzeppelin.com/)

2. **书籍**
   - 《Mastering Ethereum》
   - 《Hands-On Smart Contract Development》
   - 《The Infinite Machine》

3. **视频课程**
   - Patrick Collins的Solidity课程
   - Dapp University的Web3开发教程
   - Eat The Blocks的DeFi开发系列

### 5.2 开发工具

1. **开发框架**
   - Hardhat
   - Foundry
   - Truffle

2. **测试工具**
   - Waffle
   - Chai
   - Mocha

3. **分析工具**
   - Slither
   - Mythril
   - Tenderly

### 5.3 社区资源

1. **论坛**
   - Ethereum StackExchange
   - r/ethdev Reddit
   - Discord社区（OpenZeppelin, Ethers.js等）

2. **博客**
   - Ethereum.org博客
   - ConsenSys博客
   - Paradigm研究博客

3. **Twitter账号**
   - @VitalikButerin
   - @gakonst
   - @samczsun