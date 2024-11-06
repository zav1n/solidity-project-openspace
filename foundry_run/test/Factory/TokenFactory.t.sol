// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MyToken} from "@src/Factory/MyToken.sol";
import "@src/Factory/TokenFactory.sol";



contract TokenFactoryTest is Test {
    MyToken token;
    TokenFactory tokenFactory;
    ERC1967Proxy proxy;

    string public symbol = "MTK";
    uint public totalSupply = 1_000_000;
    uint public perMint = 10;


    Account public owner = makeAccount("owner");
    Account public alice = makeAccount("alice");
    function setUp() public {
      token = new MyToken();
      token.initialize(msg.sender, symbol, totalSupply, perMint);
      TokenFactory impl = new TokenFactory();

      proxy = new ERC1967Proxy(
          address(impl),
          abi.encodeCall(impl.initialize, owner.addr)
      );

      tokenFactory = TokenFactory(address(proxy));
    }

    function test_deployInscription() public {
      vm.prank(owner.addr);
      tokenFactory.deployInscription(symbol, totalSupply, perMint);

      // 获取刚刚部署的token地址
      address deployedTokenAddress = tokenFactory.deployedTokens(0);
      MyToken deployedToken = MyToken(deployedTokenAddress);

      assertEq(deployedToken.symbol(), symbol);
      assertEq(deployedToken.totalSupply(), 0);
      assertEq(deployedToken.totalSupplyToken(), totalSupply);
      assertEq(deployedToken.perMint(), perMint);
      assertEq(deployedToken.owner(), owner.addr);

      // alice 去创建新的token
      vm.prank(alice.addr);
      tokenFactory.deployInscription(symbol, totalSupply, perMint);

      // 获取刚刚部署的token地址
      address token2Addr = tokenFactory.deployedTokens(1);
      MyToken token2 = MyToken(token2Addr);

      assertEq(token2.symbol(), symbol);
      assertEq(token2.totalSupply(), 0);
      assertEq(token2.totalSupplyToken(), totalSupply);
      assertEq(token2.perMint(), perMint);
      assertEq(token2.owner(), alice.addr);
    }

    function test_mintInscription() public {
      vm.prank(owner.addr);
      tokenFactory.deployInscription(symbol, totalSupply, perMint);

      address tokenAddr = tokenFactory.deployedTokens(0);
      MyToken token3 = MyToken(tokenAddr);
      vm.startPrank(alice.addr);
      tokenFactory.mintInscription(tokenAddr);
      assertEq(token3.balanceOf(alice.addr), 10 ether);
      assertEq(token3.totalSupply(), 10 ether);
      assertEq(token3.totalSupplyToken(), totalSupply);
      vm.stopPrank();
    }
}
