## EigenLayer 的代码架构

https://x.com/seek_web3/status/1840687221835464959

- Eigenpod和EigenpodManager是什么  
EigenPod 和 EigenPodManager 是 EigenLayer 的核心组件，主要用于支持 再质押（Restaking）  
EigenLayer 是一个去中心化的协议，用于支持 再质押（Restaking）。它允许以太坊验证者或质押者通过重复利用其质押的 ETH 来为其他区块链协议或服务提供安全性和支持。  

**EigenPod**： 一个专门的智能合约，用于托管验证者的质押资产和支持流动性质押功能。  
**EigenPodManager**： 一个协调和管理多个 EigenPods 的工具，确保再质押操作的安全性和效率。  
两者共同构成了 EigenLayer 的重要基础设施，为以太坊生态系统提供了更高的安全性和资本效率，同时降低了用户参与多协议的复杂性。
