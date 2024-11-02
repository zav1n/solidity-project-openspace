## foundry test file
test NFTMarketplace.sol: test/Signature/NFTMarketplace.t.sol
test TokenBank.sol: test/Signature/TokenBankPermit.t.sol

EIP 712 和 EIP2612 的区别是什么
EIP-712 和 EIP-2612 是两个不同的以太坊提案（EIP），它们有不同的目的，但可以协同工作。让我们分别解释它们的定义和区别。

1. EIP-712：Typed Structured Data Hashing and Signing
EIP-712 是关于 结构化数据的哈希和签名 的标准，允许以太坊用户对结构化数据进行安全的、可读的、离线的签名。

主要特点：
结构化数据签名：EIP-712 允许对结构化数据进行签名，而不仅仅是对哈希值进行签名。这种方式确保签名的数据是人类可读的，从而可以防止用户在签名时被欺骗。
人类可读性：因其支持结构化数据签名，用户可以看到数据的具体字段并理解他们正在签名的内容，而不是面对难以理解的哈希值。
防止重放攻击：EIP-712 引入了域分隔符（Domain Separator），它可以防止不同应用或不同链之间的重放攻击。每个应用程序或智能合约可以有不同的域分隔符，确保签名只在特定上下文中有效。
EIP-712 的主要目的是针对需要用户签署复杂数据结构的场景，确保签名过程是安全且透明的。它为复杂合约交互提供了一种安全且标准化的签名方式。

用法场景：
签署具有多个字段的复杂交易数据。
在去中心化应用（DApps）中，要求用户对特定内容（如订单、授权、消息等）进行签名。
例子：
EIP-712 可以用于去中心化交易所（DEX）中对订单进行签名，用户可以离线签名订单数据，确保其安全性和透明性。

2. EIP-2612：Permit - 712-signed approvals for ERC-20 tokens
EIP-2612 基于 EIP-712，它是对 ERC-20 代币的扩展，允许用户通过离线签名的方式来批准 ERC-20 代币的支出，而无需先调用 approve()。

主要特点：
基于 EIP-712：EIP-2612 利用了 EIP-712 的结构化数据签名标准，允许用户对 permit 结构化数据进行签名。
permit 函数：引入了一个新的 permit 函数，允许用户通过签名和授权来批准代币转账。这意味着用户可以通过一次交易完成授权和转账，而不是传统的两次交易（分别调用 approve 和 transferFrom）。
Gas 优化：EIP-2612 减少了用户在使用 ERC-20 代币时需要进行的交易次数，从而降低了使用代币时的 Gas 成本。
无需账户余额：用户可以在没有足够以太币支付 Gas 的情况下，依然通过 permit 函数进行授权，因为签名可以离线完成。
EIP-2612 的主要目的是简化 ERC-20 代币的使用体验，特别是减少授权操作的复杂性和成本。

用法场景：
用户想要将代币授权给另一个地址（如智能合约）进行支出，而不需要先调用 approve() 再调用 transferFrom()。
去中心化交易所（DEX）或其他需要频繁代币授权的应用场景。
例子：
典型的应用场景是在去中心化交易所（如 Uniswap）中，用户可以通过签名离线授权代币支出权限，然后 DEX 智能合约可以调用 permit 函数来完成代币授权和支付。

3. EIP-712 和 EIP-2612 的区别
目的不同：
EIP-712：提供了一个通用的结构化数据签名标准，适用于所有需要用户签署复杂数据的场景，包括但不限于代币授权、交易订单签名等。
EIP-2612：是一个基于 EIP-712 的特定扩展，专门用于 ERC-20 代币的离线授权，简化了代币的 approve 过程。
应用场景不同：
EIP-712：可以用于任何需要结构化数据签名的场景，如去中心化交易所中的订单签名、DAO 中的投票签名等。
EIP-2612：专门用于简化 ERC-20 代币的授权流程，通过 permit 函数允许用户通过签名方式授权代币的使用。
功能范围不同：
EIP-712：是一个更广泛的标准，可以用于签名任何类型的结构化数据。
EIP-2612：是一个更狭窄的标准，主要用在 ERC-20 代币的 permit 授权流程中。
4. 总结
EIP-712 是一个通用的标准，用于在以太坊上签署结构化数据，使得签名过程更加安全、透明且易于理解。它广泛应用于各种需要复杂数据签名的场景。
EIP-2612 是基于 EIP-712 的一个扩展，用于简化 ERC-20 代币的授权过程，允许用户通过离线签名的方式授权代币支出，而不需要分别调用 approve 和 transferFrom，从而节省了 Gas 费用并提升了用户体验。
EIP-2612 的实现依赖 EIP-712，但它专注于代币的 permit 授权功能，而 EIP-712 是一个更通用的标准，适用于多种场景。