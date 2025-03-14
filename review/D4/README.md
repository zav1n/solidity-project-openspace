# OpenSpace NFT 项目

## 项目介绍

这是一个完整的NFT铸造DApp项目，包含智能合约和前端应用。该项目实现了以下功能：

### 高级合约功能
- 继承与接口（使用OpenZeppelin的ERC721合约）
- 库的使用（使用Counters库）
- OpenZeppelin合约集成（ERC721、Ownable）

### 前端高级功能
- 多链支持（通过MultiChainWallet组件）
- ENS集成（通过ENSResolver组件）
- 签名验证（通过SignatureVerifier组件）

### 项目完善
- 完成了NFT铸造DApp
  - 智能合约：支持铸造、查询和提款
  - 前端：支持铸造NFT和展示已拥有的NFT
- 测试与调试（使用Hardhat进行合约测试）

## 技术栈

- 智能合约：Solidity + OpenZeppelin
- 测试框架：Hardhat
- 前端：React + TypeScript + Vite
- Web3交互：ethers.js + wagmi

## 项目结构

```
/
├── contracts/           # 智能合约
│   └── OpenspaceNFT.sol # NFT合约
├── frontend/           # 前端应用
│   ├── src/
│   │   ├── components/ # React组件
│   │   └── services/   # 合约交互服务
├── scripts/            # 部署脚本
├── test/               # 合约测试
└── hardhat.config.js   # Hardhat配置
```

## 运行指南

### 安装依赖

```bash
# 安装根目录依赖（Hardhat等）
npm install

# 安装前端依赖
cd frontend
npm install
```

### 编译合约

```bash
npm run compile
```

### 运行测试

```bash
npm test
```

### 部署合约

```bash
# 启动本地节点
npm run node

# 在新的终端窗口部署合约
npm run deploy
```

### 运行前端

```bash
cd frontend
npm run dev
```

## 功能说明

1. **NFT铸造**：用户可以通过支付ETH铸造NFT
2. **NFT展示**：用户可以查看自己拥有的NFT
3. **多链钱包**：支持连接不同的区块链网络
4. **ENS解析**：支持解析以太坊域名
5. **签名验证**：支持消息签名和验证