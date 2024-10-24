// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./MyToken.sol";
import "./TokenBank.sol";
import "./MyNFT.sol";
import "./NFTMarket.sol";

contract TokenBankTest is Test {
    MyToken public myToken;
    TokenBank public tokenBank;
    MyNFT public myNFT;
    NFTMarket public nftMarket;

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(1);
        user2 = address(2);

        // 部署 MyToken
        myToken = new MyToken();

        // 部署 TokenBank，接受 MyToken 作为存款
        tokenBank = new TokenBank(IERC20(address(myToken)));

        // 部署 MyNFT
        myNFT = new MyNFT();

        // 部署 NFTMarket，接受 MyToken 作为支付货币
        nftMarket = new NFTMarket(myNFT, IERC20(address(myToken)));

        // 项目方铸造 NFT 并上架
        myNFT.createNFT(owner, "ipfs://tokenURI/1");
    }

    function testPermitDeposit() public {
        uint256 amount = 100 ether;

        // 给 user1 分配代币
        myToken.transfer(user1, amount);

        // user1 生成 permit 签名
        uint256 deadline = block.timestamp + 1 days;
        uint256 nonce = myToken.nonces(user1);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                myToken.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(myToken.PERMIT_TYPEHASH(), user1, address(tokenBank), amount, nonce, deadline))
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);

        // user1 使用 permitDeposit 进行存款
        vm.prank(user1);
        tokenBank.permitDeposit(amount, deadline, v, r, s);

        assertEq(tokenBank.balances(user1), amount);
    }

    function testPermitBuy() public {
        uint256 price = 100 ether;
        uint256 tokenId = 0;

        // 给 user1 分配代币
        myToken.transfer(user1, price);

        // 项目方签名，允许 user1 购买 NFT
        uint256 deadline = block.timestamp + 1 days;
        bytes32 hash = keccak256(abi.encodePacked(user1, tokenId, price, deadline));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0, keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)));

        // user1 使用 permitBuy 购买 NFT
        vm.prank(user1);
        myToken.approve(address(nftMarket), price);
        nftMarket.permitBuy(tokenId, price, deadline, v, r, s);

        assertEq(myNFT.ownerOf(tokenId), user1);
    }
}