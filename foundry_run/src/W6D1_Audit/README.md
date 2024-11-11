
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
