// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC20Token} from "@src/Factory/ERC20Token.sol";
import {TokenFactoryV1} from "@src/Factory/TokenFactoryV1.sol";
import {TokenFactoryV2} from "@src/Factory/TokenFactoryV2.sol";

contract TokenFactoryV1Test is Test {
    TokenFactoryV1 public factoryv1;
    TokenFactoryV2 public factoryv2;
    ERC20Token public myToken;
    ERC20Token deployedToken;

    ERC1967Proxy proxy;
    Account public owner = makeAccount("owner");
    Account public newOwner = makeAccount("newOwner");
    Account public user = makeAccount("user");

    string public symbol = "ETK";
    uint public totalSupply = 1_000_000 ether;
    uint public perMint = 10 ether;
    uint public price = 10 ** 16; // 0.01 ETH in wei

    function setUp() public {
        myToken = new ERC20Token();
        myToken.initialize(msg.sender, symbol, totalSupply, perMint);
        // 部署实现
        TokenFactoryV1 implementation = new TokenFactoryV1();
        // Deploy the proxy and initialize the contract through the proxy
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeCall(implementation.initialize, owner.addr)
        );
        // 用代理关联 TokenFactoryV1 接口
        factoryv1 = TokenFactoryV1(address(proxy));
        // Emit the owner address for debugging purposes
        emit log_address(owner.addr);
    }

    function testTokenFactoryV1DeployInscriptionFunctionality() public {
        vm.prank(owner.addr);
        factoryv1.deployInscription(symbol, totalSupply, perMint);

        assertEq(factoryv1.size(), 1);
        // Fetch the deployed token address
        address deployedTokenAddress = factoryv1.deployedTokens(0);

        // Create an instance of the deployed token contract
        deployedToken = ERC20Token(deployedTokenAddress);

        // Verify token initialization
        assertEq(deployedToken.symbol(), symbol);
        assertEq(deployedToken.totalSupply(), 0);
        assertEq(deployedToken.totalSupplyToken(), totalSupply);
        assertEq(deployedToken.perMint(), perMint);

        // Optionally verify owner initialization
        assertEq(deployedToken.owner(), owner.addr);
    }

    function testTokenFactoryV1PermissionsDeployInscriptionFunctionality()
        public
    {
        vm.startPrank(user.addr);
        factoryv1.deployInscription(symbol, totalSupply, perMint);

        assertEq(factoryv1.size(), 1);
        // Fetch the deployed token address
        address deployedTokenAddress = factoryv1.deployedTokens(0);

        // Create an instance of the deployed token contract
        deployedToken = ERC20Token(deployedTokenAddress);

        // Verify token initialization
        assertEq(deployedToken.symbol(), symbol);
        assertEq(deployedToken.totalSupply(), 0);
        assertEq(deployedToken.totalSupplyToken(), totalSupply);
        assertEq(deployedToken.perMint(), perMint);

        // Optionally verify owner initialization
        assertEq(deployedToken.owner(), user.addr);
        vm.stopPrank();
    }

    function testTokenFactoryV1MintInscriptionFunctionality() public {
        vm.prank(owner.addr);
        factoryv1.deployInscription(symbol, totalSupply, perMint);

        assertEq(factoryv1.size(), 1);
        // Fetch the deployed token address
        address deployedTokenAddress = factoryv1.deployedTokens(0);
        deployedToken = ERC20Token(deployedTokenAddress);
        vm.startPrank(user.addr);
        factoryv1.mintInscription(deployedTokenAddress);
        assertEq(deployedToken.balanceOf(user.addr), 10 ether);
        assertEq(deployedToken.totalSupply(), 10 ether);
        assertEq(deployedToken.totalSupplyToken(), totalSupply);
        vm.stopPrank();
    }

    function testTokenFactoryV1PermissionsMintInscriptionFunctionality()
        public
    {
        vm.startPrank(user.addr);
        factoryv1.deployInscription(symbol, totalSupply, perMint);

        assertEq(factoryv1.size(), 1);
        // Fetch the deployed token address
        address deployedTokenAddress = factoryv1.deployedTokens(0);
        deployedToken = ERC20Token(deployedTokenAddress);

        factoryv1.mintInscription(deployedTokenAddress);
        assertEq(
            ERC20Token(deployedTokenAddress).balanceOf(user.addr),
            10 ether
        );
        assertEq(deployedToken.balanceOf(user.addr), 10 ether);
        assertEq(deployedToken.totalSupply(), 10 ether);
        assertEq(deployedToken.totalSupplyToken(), totalSupply);
        vm.stopPrank();
    }

    // 测试升级
    // function testUpgradeability() public {
    //     Upgrades.upgradeProxy(
    //         address(proxy),
    //         "TokenFactoryV2.sol:TokenFactoryV2",
    //         "",
    //         owner.addr
    //     );
    // }

    function testERC20Functionality() public {
        vm.startPrank(user.addr);
        factoryv1.deployInscription(symbol, totalSupply, perMint);
        address deployedTokenAddress = factoryv1.deployedTokens(0);
        deployedToken = ERC20Token(deployedTokenAddress);

        factoryv1.mintInscription(deployedTokenAddress);
        vm.stopPrank();
        assertEq(deployedToken.balanceOf(user.addr), perMint);
    }

    // function testVerifyUpgradeability() public {
    //     testERC20Functionality();
    //     vm.prank(owner.addr);
    //     // TokenFactoryV2 factoryV2 = new TokenFactoryV2();
    //     assertEq(deployedToken.balanceOf(user.addr), perMint); ///
    //     // 1. 升级代理合约
    //     Upgrades.upgradeProxy(
    //         address(proxy),
    //         "TokenFactoryV2.sol:TokenFactoryV2",
    //         "",
    //         owner.addr
    //     );
    //     // TokenFactoryV2 factoryV2 = TokenFactoryV2(address(proxy));
    //     factoryv2 = TokenFactoryV2(address(proxy));
    //     console.log("Verify upgradeability");
    //     vm.prank(owner.addr);
    //     (bool s, ) = address(proxy).call(
    //         abi.encodeWithSignature(
    //             "setTokenAddress(address)",
    //             address(myToken)
    //         )
    //     );
    //     require(s);

    //     // 验证新的功能
    //     // 2. deployInscription
    //     vm.startPrank(user.addr);
    //     deal(user.addr, price * perMint);
    //     (bool success, ) = address(proxy).call(
    //         abi.encodeWithSelector(
    //             factoryv2.deployInscription.selector,
    //             symbol,
    //             totalSupply,
    //             perMint,
    //             price
    //         )
    //     );
    //     assertEq(success, true);

    //     (bool su, bytes memory deployedTokenAddressBytes) = address(proxy).call(
    //         abi.encodeWithSelector(factoryv2.deployedTokens.selector, 0)
    //     );
    //     assertEq(su, true);
    //     address deployedTokenAddress = abi.decode(
    //         deployedTokenAddressBytes,
    //         (address)
    //     );

    //     console.log("deployedTokenAddress", deployedTokenAddress);
    //     (bool sus, bytes memory deployedTokensLengthBytes) = address(proxy)
    //         .call(abi.encodeWithSelector(factoryv2.size.selector));
    //     assertEq(sus, true);
    //     uint256 deployedTokensLength = abi.decode(
    //         deployedTokensLengthBytes,
    //         (uint256)
    //     );
    //     console.log("deployedTokensLength", deployedTokensLength);
    //     assertEq(deployedTokensLength, 2);

    //     (bool su2, bytes memory deployedTokenAddressBytes2) = address(proxy)
    //         .call(abi.encodeWithSelector(factoryv2.deployedTokens.selector, 1));
    //     assertEq(su2, true);
    //     address deployedTokenAddress2 = abi.decode(
    //         deployedTokenAddressBytes2,
    //         (address)
    //     );

    //     assertNotEq(deployedTokenAddress, deployedTokenAddress2);
    //     // 3. mintInscription
    //     deployedToken = ERC20Token(deployedTokenAddress2);
    //     (bool mintSuccess, ) = address(proxy).call{value: price * perMint}(
    //         abi.encodeWithSignature(
    //             "mintInscription(address)",
    //             deployedTokenAddress2
    //         )
    //     );
    //     require(mintSuccess, "Minting of token failed");

    //     assertEq(factoryv2.tokenPrices(deployedTokenAddress), 0);
    //     assertEq(factoryv2.tokenPrices(deployedTokenAddress2), price);
    //     assertEq(factoryv2.tokenperMint(deployedTokenAddress2), perMint);

    //     assertEq(deployedToken.balanceOf(user.addr), 10 ether);
    //     assertEq(deployedToken.totalSupply(), perMint);
    //     assertEq(deployedToken.totalSupplyToken(), totalSupply);
    //     vm.stopPrank();
    // }
}