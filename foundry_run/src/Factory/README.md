9  ### 题目: 实现⼀个可升级的工厂合约，工厂合约有两个方法：

1. deployInscription(string symbol, uint totalSupply, uint perMint) ，该方法用来创建 ERC20 token，（模拟铭文的 deploy）， symbol 表示 Token 的名称，totalSupply 表示可发行的数量，perMint 用来控制每次发行的数量，用于控制mintInscription函数每次发行的数量
2. mintInscription(address tokenAddr) 用来发行 ERC20 token，每次调用一次，发行perMint指定的数量。
要求：
- 合约的第⼀版本用普通的 new 的方式发行 ERC20 token 。
- 第⼆版本，deployInscription 加入一个价格参数 price  deployInscription(string symbol, uint totalSupply, uint perMint, uint price) , price 表示发行每个 token 需要支付的费用，并且 第⼆版本使用最小代理的方式以更节约 gas 的方式来创建 ERC20 token，需要同时修改 mintInscription 的实现以便收取每次发行的费用。


<img width="30%" src="https://github.com/user-attachments/assets/b929d628-b155-4f21-ba9b-ce4c0f8434cf">






### 升级方式

#### 透明代理 (Transparent Prox) ERC-1967

<img width="70%" src="https://github.com/user-attachments/assets/d0f10246-4964-44e6-b9ea-13e8a9f91457">

透明代理模式旨在区分管理员和普通用户。它通过使用两个不同的地址来工作：一个用于管理员（可以升级合约），另一个用于普通用户（可以与合约的函数交互）。代理合约包括了区分管理员调用和普通用户调用的逻辑，防止在常规使用过程中意外执行管理功能。

TransparentProxy Demo: [TransparentProxy.sol](https://github.com/zav1n/solidity-project-openspace/blob/v1.2.0/foundry_run/src/Proxy/TransparentProxy.sol)


#### UUPS 代理 (universal upgradeable proxy standard) ERC-1822

<img width="70%" src="https://github.com/user-attachments/assets/84f376e9-bd82-4fd0-a055-764dc68c42eb">

UUPS（通用可升级代理标准）代理是一种更简化和更节省 gas 的方法。在这种模式中，升级功能嵌入在逻辑合约本身中。这种设计减少了对额外'管理员'合约的需求，简化了结构。但是，它也要求逻辑合约在设计时考虑到可升级性，在其中嵌入必要的升级功能.

UUPSProxy Demo: [UUPSProxy.sol](https://github.com/zav1n/solidity-project-openspace/blob/v1.2.0/foundry_run/src/Proxy/UUPSProxy.sol)

#### 钻石代理 EIP-2535 Diamonds（钻石）
<img width="70%" src="https://github.com/user-attachments/assets/64c1afff-26c1-439e-8b73-c14c37b33296">

支持构建可在生产中扩展的模块化智能合约系统的标准。钻石是具有多个实施合约的代理合约。

#### Beacon 代理(信标代理)
<img width="60%" src="https://github.com/user-attachments/assets/41d0e85a-b5b8-418e-99b8-8e3c86bfb552">

Beacon 代理模式引入了一个中央的“信标（Beacon）”合约，所有代理实例都引用该合约以获取当前逻辑合约的地址。这种设计允许更高效的升级过程，因为在信标中更新逻辑合约地址会自动更新所有关联的代理。在需要保持多个代理合约与同一逻辑合约同步的情况下，这是特别有用的。

#### 最小代理合约 (Minimal Proxy Contract) ERC-1167

要了解更多关于代理的信息，请查看这个 QuickNode 指南[12]和OpenZeppelin 代理[13]。

### 代理相关依赖包(openzeppelin)
- ERC20Upgradeable - 包含可升级功能的 ERC-20 代币
- OwnableUpgradeable - 仅允许所有者执行某些功能（所有者可以被转移）
- ERC20PermitUpgradeable - 添加了一个许可功能，用户可以使用它来节省离线批准的成本
- Initializable - 类似于构造函数，我们将使用它来设置代币的初始参数
- UUPSUpgradeable - 我们的 ERC-20 代币将继承的通用可升级代理标准模式逻辑
- Clones - 最小代理合约

### 升级注意事项
- 用户操作的是代理，但无法阻止直接和逻辑合约交互。
- 逻辑合约状态的任何更改不会影响到代理，但是逻辑合约销毁除外。
- 如果已经使用了最小代理，将无法在使用升级，此时可考虑使用 Beacon 模式


> 参考资料

[用 OpenZeppelin 和 Foundry 创建和部署可升级的 ERC20 代币](https://foresightnews.pro/article/detail/52568)

[可升级的工厂合约](https://learnblockchain.cn/article/8878)
