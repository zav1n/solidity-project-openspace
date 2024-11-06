// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {MyToken} from "./MyToken.sol";

contract TokenFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    MyToken myToken;
    address[] public deployedTokens;

    // 使用了UUPSUpgradeable就要在构造函数里面使用_disableInitializers() 来初始化代理合约
    constructor() {
      _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
      __Ownable_init(initialOwner);
      __UUPSUpgradeable_init();
    }

    /**
     * 该方法用来创建 ERC20 token，（模拟铭文的 deploy），
     * symbol 表示 Token 的名称，totalSupply 表示可发行的数量
     * perMint 用来控制每次发行的数量, 用于控制mintInscription函数每次发行的数量
     */
    function deployInscription(
      string memory symbol,
      uint totalSupply,
      uint perMint
    ) public {
      myToken = new MyToken();
      myToken.initialize(msg.sender, symbol, totalSupply, perMint);

      deployedTokens.push(address(myToken));
    }

    /**
     *  用来发行 ERC20 token，每次调用一次，发行perMint指定的数量
     */
    function mintInscription(address tokenAddr) public {
      MyToken token = MyToken(tokenAddr); 
      token.mint(msg.sender); 
    }

    function _authorizeUpgrade(
      address newImplementation
    ) internal override onlyOwner {}
}