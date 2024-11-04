### Token 质押挖矿,挖矿得到 esRNT，esRNT 可兑换成 RNT
1. stakepool: 一个流动性池子, 可以质押RNT, 解押RNT, 以及产生的收益(奖励)获取esRNT
+ 用RNT买入(这时候是不会立马获取到等价的esRNT), 可以随时赎回RNT
+ 收益: 本金 * 10% = 1天的利润, 收益去兑换esRNT

2. RNT: 是一个流动性ERC20的Token

3. esRNT: 一个质押token, 虽然也是ERC20, 但是性质不一样不会在市面上流动, 只会在stakepool流动, 去兑换RNT的逻辑
+ 锁仓性: 不能直接转让或兑换
+ 当esRNT被兑换的时候, 兑换RNT并且burn掉

> stakepool是一个当铺, 老百姓们可以拿手上的当票(esRNT)兑换银两. 而老百姓在当铺抵押的货物每天都可以产生当票

代码设计

![image](https://github.com/user-attachments/assets/71bfc0b4-b689-43f9-909e-42eeb9342dd4)

整体逻辑

![image](https://github.com/user-attachments/assets/44c4f991-bb3d-4d18-ac0d-e64ccc5762ad)


参考: https://learnblockchain.cn/article/8826
