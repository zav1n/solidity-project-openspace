// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {MyToken} from "@src/Factory/MyToken.sol";
import "@src/Factory/TokenFactory.sol";


contract TokenFactoryTest is Test {
    MyToken token;
    TokenFactory tokenFactory;
    address factoryAddress;
    ERC1967Proxy proxy;
    address proxyAddress;

    string public symbol = "MTK";
    string public name = "MyToken";
    uint public totalSupply = 1_000_000 ether;
    uint public perMint = 10 ether;


    Account public owner = makeAccount("owner");
    Account public alice = makeAccount("alice");

    struct deployedToken {
      uint perMint;
      uint totalSupply;
    }

    function setUp() public {
      token = new MyToken();
      token.initialize(msg.sender, name, symbol);
      TokenFactory impl = new TokenFactory();

      proxy = new ERC1967Proxy(
          address(impl),
          abi.encodeCall(impl.initialize, owner.addr)
      );

      tokenFactory = TokenFactory(address(proxy));

      vm.prank(owner.addr);
      (bool success, ) = address(proxy).call(
          abi.encodeWithSelector(
            tokenFactory.setTokenAddress.selector,
            address(token)
          )
      );

      require(success);
    }

    // 测试 ERC1967Proxy 升级: 如果使用的是1967Proxy
    function test_Upgradeability() public {
      Upgrades.upgradeProxy(
        address(proxy),
        "TokenFactoryV2.sol",
        "",
        owner.addr
      );
    }
    function test_deployInscription() public {
      vm.prank(owner.addr);
      address tokenAddr1 = tokenFactory.deployInscription(name, symbol, totalSupply, perMint);

      MyToken token1 = MyToken(tokenAddr1);
      (uint token1PerMint, uint token1TotalSupply) = tokenFactory.tokens(tokenAddr1);

      assertEq(token1.name(), name);
      assertEq(token1.symbol(), symbol);
      assertEq(token1.totalSupply(), 0);
      assertEq(token1TotalSupply, totalSupply);
      assertEq(token1PerMint, perMint);
      assertEq(token1.owner(), owner.addr);

      // alice 去创建新的token
      vm.prank(alice.addr);
      address tokenAddr2 = tokenFactory.deployInscription(name ,symbol, totalSupply, perMint);
      MyToken token2 = MyToken(tokenAddr2);
      (uint token2PerMint, uint token2TotalSupply) = tokenFactory.tokens(tokenAddr2);

      assertEq(token2.symbol(), symbol);
      assertEq(token2.totalSupply(), 0);
      assertEq(token2TotalSupply, totalSupply);
      assertEq(token2PerMint, perMint);
      assertEq(token2.owner(), alice.addr);
    }

    function test_mintInscription() public {
      vm.prank(owner.addr);
      address tokenAddr = tokenFactory.deployInscription(name, symbol, totalSupply, perMint);
      (,uint token3TotalSupply) = tokenFactory.tokens(tokenAddr);
      MyToken token3 = MyToken(tokenAddr);
      vm.startPrank(alice.addr);
        tokenFactory.mintInscription(tokenAddr);
        assertEq(token3.balanceOf(alice.addr), 10 ether);
        assertEq(token3.totalSupply(), 10 ether);
        assertEq(token3TotalSupply, totalSupply);
      vm.stopPrank();
    }
}
