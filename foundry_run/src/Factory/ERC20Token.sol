// // SPDX-License-Identifier: MIT
// // Compatible with OpenZeppelin Contracts ^5.0.0
// pragma solidity ^0.8.20;

// // 包含可升级功能的 ERC-20 代币
// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// // 可升级的代币烧毁功能
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
// // 可暂停功能。在紧急情况下暂停所有转账操作
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
// // 仅允许所有者执行某些功能（所有者可以被转移）
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// // 添加了一个许可功能，用户可以使用它来节省离线批准的成本
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
// // 允许持有者在治理或决策过程中通过投票权重（通常基于他们持有的代币数量）参与治理, 不丢失状态的情况下进行更新
// import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
// // 类似于构造函数，我们将使用它来设置代币的初始参数
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// // 我们的 ERC-20 代币将继承的通用可升级代理标准模式逻辑
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import {Script, console} from "forge-std/Script.sol";

// contract ERC20Token is
//     Initializable,
//     ERC20Upgradeable,
//     ERC20BurnableUpgradeable,
//     ERC20PausableUpgradeable,
//     OwnableUpgradeable,
//     ERC20PermitUpgradeable,
//     ERC20VotesUpgradeable
// {
//     uint public totalSupplyToken;
//     uint public perMint;

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() {
//         // _disableInitializers();
//     }

//     /**
//      * initializes the token
//      * @param initialOwner the initial owner
//      * @param _symbol symbol 表示 Token 的名称
//      * @param _totalSupply totalSupply 表示可发行的数量
//      * @param _perMint perMint 用来控制每次发行的数量
//      *
//      */
//     function initialize(
//         address initialOwner,
//         string memory _symbol,
//         uint _totalSupply,
//         uint _perMint
//     ) public initializer {
//         __ERC20_init("ERC20Token", _symbol);
//         __ERC20Burnable_init();
//         __ERC20Pausable_init();
//         __Ownable_init(initialOwner);
//         __ERC20Permit_init("ERC20Token");
//         __ERC20Votes_init();
//         perMint = _perMint;
//         totalSupplyToken = _totalSupply;
//     }

//     function pause() public onlyOwner {
//         _pause();
//     }

//     function unpause() public onlyOwner {
//         _unpause();
//     }

//     function mint(address to) public {
//         uint currentSupply = totalSupply(); // 获取当前代币供应量
//         // 确保铸造后总供应量不超过最大供应量
//         require(
//           currentSupply + perMint <= totalSupplyToken,
//           "Exceeds max total supply"
//         );
//         _mint(to, perMint);
//     }

//     // The following functions are overrides required by Solidity.

//     function _update(
//         address from,
//         address to,
//         uint256 value
//     )
//         internal
//         override(
//             ERC20Upgradeable,
//             ERC20PausableUpgradeable,
//             ERC20VotesUpgradeable
//         )
//     {
//         super._update(from, to, value);
//     }

//     function nonces(
//         address owner
//     )
//         public
//         view
//         override(ERC20PermitUpgradeable, NoncesUpgradeable)
//         returns (uint256)
//     {
//         return super.nonces(owner);
//     }
// }