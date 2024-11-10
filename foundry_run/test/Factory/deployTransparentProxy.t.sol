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

      // tokenFactory = new TokenFactory();
      // factoryAddress = address(tokenFactory);
      vm.startPrank(owner.addr);
        bytes memory initData = new bytes(0);
        // 使用透明代理
        proxyAddress = Upgrades.deployTransparentProxy("TokenFactory.sol", owner.addr, initData);
      vm.stopPrank();
    
    }

    // 测试透明代理升级
    function test_upgrade() public {
      vm.startPrank(owner.addr);
        Upgrades.upgradeProxy(
            proxyAddress,
            "TokenFactoryV2.sol",
            abi.encodeCall(TokenFactory.initialize, (owner.addr))
        );
    }
    function test_deployInscription() public {
      address user1 = vm.randomAddress();
      address user2 = vm.randomAddress();
      address user3 = vm.randomAddress();
      
      TokenFactory factoryProxy = TokenFactory(proxyAddress);
      
      //owner deploy
      vm.startPrank(owner.addr);
        factoryProxy.initialize(owner.addr);
        address tokenAddr1 = factoryProxy.deployInscription(name, symbol, totalSupply, perMint);
      vm.stopPrank();

      MyToken token1 = MyToken(tokenAddr1);
      address tokenAddress = address(token1);
      (uint token1PerMint, uint token1TotalSupply) = factoryProxy.tokens(tokenAddress);

      assertEq(token1.name(), name);
      assertEq(token1.symbol(), symbol);
      assertEq(token1.totalSupply(), 0);
      assertEq(token1TotalSupply, totalSupply);
      assertEq(token1PerMint, perMint);
      assertEq(token1.owner(), owner.addr);

      //user 2 mint
      vm.prank(user2);
      factoryProxy.mintInscription(tokenAddr1);
      //user 3 mint
      vm.prank(user3);
      factoryProxy.mintInscription(tokenAddr1);
      //user 3 mint again
      vm.prank(user3);
      factoryProxy.mintInscription(tokenAddr1);
      console.log("tokenAddr1", tokenAddr1);
      console.log("MyToken(tokenAddr1)", address(MyToken(tokenAddr1)));
      // balanceOf user 1
      console.log('user1 balance',MyToken(tokenAddr1).balanceOf(user1));
      //balanceOf user 2
      console.log('user2 balance',MyToken(tokenAddr1).balanceOf(user2));
      //balanceOf user 3
      console.log('user3 balance',MyToken(tokenAddr1).balanceOf(user3));
      //token real totalSupply
      console.log('token real totalSupply', MyToken(tokenAddr1).totalSupply());
      
      assertEq(MyToken(tokenAddr1).balanceOf(user1),0,"deployer own 0 initial");
      assertEq(MyToken(tokenAddr1).balanceOf(user2),perMint,"mint wrong");
      assertEq(MyToken(tokenAddr1).balanceOf(user3),perMint*2,"multi mint wrong");
    }

}
