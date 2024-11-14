// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ERC20Token} from "./ERC20Token.sol";

contract TokenFactoryV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    ERC20Token myToken;
    address[] public deployedTokens;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //   _disableInitializers();
    // }

    function initialize(address initialOwner) public initializer {
      __Ownable_init(initialOwner);
      __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
      address newImplementation
    ) internal override onlyOwner {}

    /**
     * 该方法用来创建 ERC20 token，（模拟铭文的 deploy）
     * @param symbol symbol 表示 Token 的名称
     * @param totalSupply totalSupply 表示可发行的数量，
     * @param perMint perMint 用来控制每次发行的数量，用于控制mintInscription函数每次发行的数量
     * @dev Deploys a new ERC20Token contract with the given parameters and adds it to the deployedTokens array.
     *
     * deployInscription(string symbol, uint totalSupply, uint perMint)
     *
     */
    function deployInscription(
      string memory symbol,
      uint totalSupply,
      uint perMint
    ) public {
      myToken = new ERC20Token();
      myToken.initialize(msg.sender, symbol, totalSupply, perMint);
      // console.log("deployInscription newToken: ", address(myToken));

      deployedTokens.push(address(myToken));
    }

    /**
     * 该方法用来给用户发行 token
     * @param tokenAddr tokenAddr 表示要发行 token 的地址
     * @dev Mints tokens to the caller address using the ERC20Token contract at the given address.
     *
     * mintInscription(address tokenAddr) 用来发行 ERC20 token，每次调用一次，发行perMint指定的数量。
     */
    function mintInscription(address tokenAddr) public {
      ERC20Token token = ERC20Token(tokenAddr); // Correctly cast the address to the ERC20Token type
      token.mint(msg.sender); // Assuming ERC20Token has a mint function with (address, uint256) parameters
    }

    function size() public view returns (uint) {
      return deployedTokens.length;
    }
}