### permit2: 解决没有使用permit的ERC20

TokenBank.sol 实现 permit2 功能来兼容ERC20
1. 实现 depositWithPermit2( IERC20 token, uint256 amount, PermitTransferFrom memory permit, bytes calldata signature)
2. 输出测试用例
3. 前端签名完之后, 调用合约depositWithPermit2