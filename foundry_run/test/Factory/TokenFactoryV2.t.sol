// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {TokenFactoryV2} from "@src/Factory/TokenFactoryV2.sol";
import {ERC20Token} from "@src/Factory/ERC20Token.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract CounterTest is Test {
    TokenFactoryV2 public factoryv2;

    ERC20Token public myToken;
    ERC1967Proxy proxy;
    ERC1967Proxy proxy2;
    Account public owner = makeAccount("owner");
    Account public user = makeAccount("user");

    string public symbol = "ETK";
    uint public totalSupply = 1_000_000 ether;
    uint public perMint = 10 ether;
    uint public price = 10 ** 16; // 0.01 ETH in wei
    address public tokenAddr;

    function setUp() public {
        myToken = new ERC20Token();
        myToken.initialize(msg.sender, symbol, totalSupply, perMint);

        TokenFactoryV2 implementationV2 = new TokenFactoryV2();
        vm.prank(owner.addr);
        proxy = new ERC1967Proxy(
            address(implementationV2),
            abi.encodeCall(implementationV2.initialize, (owner.addr))
        );

        // 用代理关联 TokenFactoryV2 接口
        factoryv2 = TokenFactoryV2(address(proxy));

        vm.prank(owner.addr);
        (bool success, ) = address(proxy).call(
            abi.encodeWithSelector(
                factoryv2.setTokenAddress.selector,
                address(myToken)
            )
        );

        require(success);

        // Emit the owner address for debugging purposes
        emit log_address(owner.addr);
    }

    function testTokenFactoryV2DeployInscriptionFunctionality() public {
        vm.startPrank(owner.addr);
        factoryv2.deployInscription(symbol, totalSupply, perMint, price);

        assertEq(factoryv2.size(), 1);

        // Fetch the deployed token address
        address deployedTokenAddress = factoryv2.deployedTokens(0);
        assertEq(factoryv2.tokenPrices(deployedTokenAddress), price);
        // Create an instance of the deployed token contract
        ERC20Token deployedToken = ERC20Token(deployedTokenAddress);
        assertEq(address(deployedToken), deployedTokenAddress);
        // Verify token initialization
        assertEq(deployedToken.symbol(), symbol);
        assertEq(deployedToken.balanceOf(owner.addr), 0);
        assertEq(deployedToken.totalSupplyToken(), totalSupply);
        assertEq(deployedToken.perMint(), perMint);

        // Optionally verify owner initialization
        assertEq(deployedToken.owner(), owner.addr);
        vm.stopPrank();
    }

    function testTokenFactoryV2PermissionsDeployInscriptionFunctionality()
        public
    {
        vm.startPrank(user.addr);
        factoryv2.deployInscription(symbol, totalSupply, perMint, price);

        assertEq(factoryv2.size(), 1);

        // Fetch the deployed token address
        address deployedTokenAddress = factoryv2.deployedTokens(0);
        assertEq(factoryv2.tokenPrices(deployedTokenAddress), price);
        // Create an instance of the deployed token contract
        ERC20Token deployedToken = ERC20Token(deployedTokenAddress);
        assertEq(address(deployedToken), deployedTokenAddress);
        // Verify token initialization
        assertEq(deployedToken.symbol(), symbol);
        assertEq(deployedToken.balanceOf(owner.addr), 0);
        assertEq(deployedToken.totalSupplyToken(), totalSupply);
        assertEq(deployedToken.perMint(), perMint);

        // Optionally verify owner initialization
        assertEq(deployedToken.owner(), user.addr);
        vm.stopPrank();
    }

    function testTokenFactoryV2MintInscriptionFunctionality() public {
        vm.prank(owner.addr);
        factoryv2.deployInscription(symbol, totalSupply, perMint, price);

        assertEq(factoryv2.size(), 1);
        // Fetch the deployed token address
        address deployedTokenAddress = factoryv2.deployedTokens(0);
        ERC20Token deployedToken = ERC20Token(deployedTokenAddress);
        vm.startPrank(user.addr);
        vm.deal(user.addr, price * perMint);
        factoryv2.mintInscription{value: price * perMint}(deployedTokenAddress);
        assertEq(deployedToken.balanceOf(user.addr), 10 ether);
        assertEq(deployedToken.totalSupply(), 10 ether);
        // Verify the total supply token
        assertEq(deployedToken.totalSupplyToken(), totalSupply);
        vm.stopPrank();
    }

    function testTokenFactoryV2PermissionsMintInscriptionFunctionality()
        public
    {
        vm.startPrank(user.addr);
        factoryv2.deployInscription(symbol, totalSupply, perMint, price);

        assertEq(factoryv2.size(), 1);
        // Fetch the deployed token address
        address deployedTokenAddress = factoryv2.deployedTokens(0);
        ERC20Token deployedToken = ERC20Token(deployedTokenAddress);

        vm.deal(user.addr, price * perMint);
        factoryv2.mintInscription{value: price * perMint}(deployedTokenAddress);
        assertEq(deployedToken.balanceOf(user.addr), 10 ether);
        assertEq(deployedToken.totalSupply(), 10 ether);
        assertEq(factoryv2.tokenperMint(deployedTokenAddress), perMint);
        // Verify the total supply token
        assertEq(deployedToken.totalSupplyToken(), totalSupply);
        vm.stopPrank();
    }
}
