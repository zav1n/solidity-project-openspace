eigenlayer-contractsEigenLayer 是一组部署在以太坊上的智能合约，用于重新质押资产以保护称为 AVS（主动验证服务）的新服务。而 eigenlayer-middleware 是 Eigenlayer 的中间件合约部分，主要注册 operator 加入退出功能，在 eigenlayer-middleware 有以下这些重要的功能：  
管理 BLS 聚合公钥，在 Operator 加入或者退出是更新 BLS 聚合公钥相关的信息，这个聚合公钥用于链下服务的签名验证。  
管理 Operator 在 quorum 中的 index, Operator 加入给 Operator 分配 index, Operator 退出时更新对应的 index  
管理 Operator 的质押历史，当 Operator 注册和退出注册时更新对应的质押份额  
管理 Operator 通过 eigenlayer-contracts 合约中的 AVSDirectory 注册到 AVS 合约  

### eigenlayer-middleware 代码架构  
![image](https://github.com/user-attachments/assets/389d92c0-b977-4f40-965f-71b487676e48)  
