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

      tokenFactory = new TokenFactory();
      factoryAddress = address(tokenFactory);
      vm.startPrank(owner.addr);
        bytes memory initData = new bytes(0);
        proxyAddress = Upgrades.deployTransparentProxy("TokenFactory.sol", owner.addr, initData);
      vm.stopPrank();
    
    }


    // 测试透明代理升级: 如果使用的是deployTransparentProxy
    // function test_Upgradeability() public {
    //   tokenFactory = new TokenFactory();
    //   factoryAddress = address(tokenFactory);
    //   vm.startPrank(owner.addr);
    //     bytes memory initData = new bytes(0);
    //     proxyAddress = Upgrades.deployTransparentProxy("TokenFactory.sol", owner.addr, initData);
    //   vm.stopPrank();
    // }

}
