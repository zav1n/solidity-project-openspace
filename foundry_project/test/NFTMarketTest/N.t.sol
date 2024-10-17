// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { DecertERC721 } from "@src/NFTMarket/Decert721.sol";
import { BaseERC20 } from "@src/NFTMarket/BaseERC20.sol";
import { NFTMarket } from "@src/NFTMarket/NFTMarketV2.sol";

contract NFTMarketTest is Test {
    BaseERC20 public token;
    DecertERC721 public nft721;
    NFTMarket public market;

    address suzefeng;

    function setUp() public {
        token = new BaseERC20("USD", "USDT");
        nft721 = new DecertERC721("SeafoodMarket", "SFM");
        market = new NFTMarket(address(token), address(nft721));
        suzefeng = makeAddr("suzefeng");

        // 给 suzefeng 一些 ERC20 代币
        token.transfer(suzefeng, 1000000);
    }

    function test_listNFT_success() public {
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(suzefeng);
        market.list(tokenId, 100);

        (uint256 price, address seller) = market.listings(tokenId);
        assertEq(price, 100, "Listing price should be 100");
        assertEq(seller, suzefeng, "Seller should be suzefeng");
        assertEq(nft721.ownerOf(tokenId), address(market), "NFT should be transferred to market");
    }

    function test_listNFT_failure() public {
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(makeAddr("alice"));
        vm.expectRevert("You are not the owner");
        market.list(tokenId, 100);
    }

    function test_buyNFT_success() public {
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(suzefeng);
        market.list(tokenId, 100);

        vm.prank(makeAddr("alice"));
        token.approve(address(market), 100);
        vm.prank(makeAddr("alice"));
        market.buyNFT(makeAddr("alice"), tokenId);

        assertEq(nft721.ownerOf(tokenId), makeAddr("alice"), "NFT should be transferred to alice");
        assertEq(token.balanceOf(suzefeng), 1000100, "suzefeng should receive payment");
    }

    function test_buyNFT_self() public {
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(suzefeng);
        market.list(tokenId, 100);

        vm.prank(suzefeng);
        token.approve(address(market), 100);
        vm.prank(suzefeng);
        vm.expectRevert("NFT is not listed for sale");
        market.buyNFT(suzefeng, tokenId);
    }

    // 
    function test_buyNFT_duplicate() public {
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(suzefeng);
        market.list(tokenId, 100);

        vm.prank(makeAddr("alice"));
        token.approve(address(market), 100);
        vm.prank(makeAddr("alice"));
        market.buyNFT(makeAddr("alice"),tokenId);

        vm.prank(makeAddr("bob"));
        token.approve(address(market), 100);
        vm.prank(makeAddr("bob"));
        vm.expectRevert("NFT is not listed for sale");
        market.buyNFT(makeAddr("bob"), tokenId);
    }

    function test_buyNFT_insufficientPayment() public {
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(suzefeng);
        market.list(tokenId, 100);

        vm.prank(makeAddr("alice"));
        token.approve(address(market), 99);
        vm.prank(makeAddr("alice"));
        vm.expectRevert("Incorrect payment amount");
        market.buyNFT(makeAddr("alice"),tokenId);
    }

    function test_buyNFT_excessivePayment() public {
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(suzefeng);
        market.list(tokenId, 100);

        vm.prank(makeAddr("alice"));
        token.approve(address(market), 101);
        vm.prank(makeAddr("alice"));
        vm.expectRevert("Incorrect payment amount");
        market.buyNFT(makeAddr("alice"), tokenId);
    }

    
    function test_fuzz_listAndBuyNFT() public {
        uint256 randomPrice = uint256(keccak256(abi.encodePacked(block.timestamp))) % 10000 + 1;
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(suzefeng);
        market.list(tokenId, randomPrice);

        address randomBuyer = makeAddr("randomBuyer");
        vm.prank(randomBuyer);
        token.approve(address(market), randomPrice);
        vm.prank(randomBuyer);
        market.buyNFT(randomBuyer, tokenId);

        assertEq(nft721.ownerOf(tokenId), randomBuyer, "NFT should be transferred to randomBuyer");
    }

    function test_invariant_noTokenHolding() public {
        uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
        vm.prank(suzefeng);
        nft721.approve(address(market), tokenId);
        vm.prank(suzefeng);
        market.list(tokenId, 100);
        

        vm.prank(makeAddr("alice"));
        token.approve(address(market), 100);
        vm.prank(makeAddr("alice"));
        market.buyNFT(makeAddr("alice"), tokenId);

        assertEq(token.balanceOf(address(market)), 0, "NFTMarket should not hold any tokens");
    }
}