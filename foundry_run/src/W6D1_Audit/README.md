基于第三方服务实现合约自动化调用:
先实现一个 Bank 合约， 用户可以通过 deposit() 存款， 然后使用 ChainLink Automation 、Gelato 或 OpenZepplin Defender Action 实现一个自动化任务， 自动化任务实现：当 Bank 合约的存款超过 x (可自定义数量)时， 转移一半的存款到指定的地址（如 Owner）。





<img width="100%" src="https://github.com/user-attachments/assets/23bb1f74-56d0-4033-a020-0f1c6013d024">

1. 完整的工程、详细的文档、完备的测试
  - RektTest: https://blog.trailofbits.com/2023/08/14/can-you-pass-the-rekt-test/
2. ⼯具(初评代码): 初步了解代码量、代码结构
  - CLOC：https://github.com/AlDanial/cloc
  - Solidity  Metrics (VS Code extensions)
  - SolidityVisual developer (VS Code extensions) 

### 静态分析

- Slither: https://github.com/crytic/slither
- Aderyn: https://github.com/Cyfrin/aderyn
- Mythx：https://mythx.io/

### ⼈⼯审查
1. 熟悉EVM特性、常⻅协议、常⻅安全问题
- https://github.com/ZhangZhuoSJTU/Web3Bugs
2. 跟踪安全事件、了解新攻击点
- https://substack.com/@blockthreat
- https://solodit.xyz/
- https://rekt.news/

### 审计报告

模板: https://github.com/Cyfrin/audit-report-templating

### 监控

**⾃动监控可以促进快速响应，越快响应，损害越⼩**

- 及时知晓问题（消息通知）及处理问题（⾃动化处理）
- 监控⼤额资⾦的变化
- 监控权限的转移
- 监控关键参数的修改
- ⾃建监控
- 第三⽅节点服务提供WebHook 服务
  - OpenZepplin Defender  Monitor: https://defender.openzeppelin.com/v2/#/monitor
  - TenderlyAlerting：https://tenderly.co/alerting
  - Forta （Detection Bots）: https://app.forta.network/bots
 
### 合约⾃动化执⾏

<img width="60%" src="https://github.com/user-attachments/assets/080b79f8-ff6e-45fc-ba37-ef94e5a84bdf">

1. 如何实现周期任务/定时任务/条件任务？
2. 编写后端程序，常驻后端执行
3. 主要问题：单点故障、热钱包泄漏

### Chainlink Automation
- 可靠和去中心化的自动化平台
- 根据时间或条件自动执行合约函数
- 若按条件，需编写 Upkeep 合约
  - checkUpKeep()
  - performUpKeep()
- Gelato Func.ons
  - 按时间执⾏,⽆需代码（automated-transaction）
  - 按链上条件执⾏（Solidity Functions）， checker 合约
  - 按链下条件执⾏（Typescript Functions）
- OpenZepplin Defender Action
  - 通过web3.js / ethers.js 来定制执⾏
  - Relay:⽣成独⽴的账户
  - AutoTask
  - https://www.openzeppelin.com/defender
 
### 事故分析
- https://phalcon.blocksec.com/explorer
  - https://www.youtube.com/watch?v=eXeirKUy1XA
  - https://www.youtube.com/watch?v=uiqCrhIU0To
- FoundryTransaction ReplayTrace/Debugger
  - Cast run
- Tenderly Debugger

  
