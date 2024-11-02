### permit2: 解决没有使用permit的ERC20

TokenBank.sol 实现 permit2 功能来兼容ERC20
1. 实现 depositWithPermit2( IERC20 token, uint256 amount, PermitTransferFrom memory permit, bytes calldata signature)
2. 输出测试用例
3. 前端签名完之后, 调用合约depositWithPermit2

Uniswap Permit2 - 高效、一致和安全的授权: https://learnblockchain.cn/article/5161
Demo: https://github.com/dragonfly-xyz/useful-solidity-patterns/blob/main/patterns/permit2/Permit2Vault.sol
Test: https://github.com/dragonfly-xyz/useful-solidity-patterns/blob/main/test/Permit2Vault.t.sol