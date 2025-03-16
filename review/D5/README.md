## 第5天：安全与优化

### 合约安全深入

- **常见漏洞分析**
  - 重入攻击(Reentrancy)防范
  - 整数溢出与下溢(Overflow/Underflow)
  - 访问控制漏洞
  - 前端运行(Front-running)与交易顺序依赖
  
- **审计技巧**
  - 代码审计方法论
  - 手动审计与自动化工具结合
  - 常见审计清单(Checklist)
  
- **安全工具使用**
  - Slither静态分析
  - Mythril符号执行
  - Echidna模糊测试
  - OpenZeppelin合约库安全特性

### Gas优化

- **存储优化**
  - 变量打包(Variable Packing)
  - 使用mapping vs array
  - 存储位置选择(storage, memory, calldata)
  
- **循环优化**
  - 减少循环内计算
  - 避免动态数组增长
  - 批量操作技巧
  
- **位操作技巧**
  - 使用位图(Bitmap)存储布尔值
  - 位运算替代算术运算
  - 紧凑编码与解码

### 前端性能优化

- **React性能优化**
  - 组件拆分与重用
  - useMemo与useCallback使用
  - 虚拟列表渲染大数据
  
- **Web3调用缓存**
  - 本地状态管理
  - 事件监听优化
  - RPC请求批处理
  
- **用户体验提升**
  - 交易状态反馈
  - 加载状态优化
  - 错误处理与恢复机制