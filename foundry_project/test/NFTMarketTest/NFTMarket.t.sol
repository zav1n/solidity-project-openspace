// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DecertERC721 } from "@src/NFTMarket/Decert721.sol";
import { BaseERC20 } from "@src/NFTMarket/BaseERC20.sol";
import { NFTMarket } from "@src/NFTMarket/NFTMarketV2.sol";

contract NFTMarketTest is Test {
  DecertERC721 public nft721;
  BaseERC20 public token;
  NFTMarket public market;

  address suzefeng;
  function setUp() public {
    nft721 = new DecertERC721("SeafoodMarket", "SFM");
    token = new BaseERC20("USD", "USDT");
    market = new NFTMarket(address(token), (address(nft721)));
    suzefeng = makeAddr("suzefeng");
  }
  // 转账
  function test_erc20Transfer() public {

    uint256 value = 1000 ether;
    (bool success) = token.transfer(suzefeng, value);
    uint256 balanceThis = token.balanceOf(address(this)); // 检查还剩多少个代币
    assertEq(token.balanceOf(suzefeng), value); // 给suzefeng转100个ETH

  }

  // mint nft
  function test_nftMint() public returns(uint256, uint256) {
    string memory tokenURL = "ipfs://Qmdg226knQTkw9A2kY4wng54RtE4TTXXAPqJF5Mu7qpWcp";
    uint256 upAmount = 55 ether;
    (uint256 tokenId) = nft721.mint(suzefeng, tokenURL);
    token.balanceOf(suzefeng);
    return(upAmount, tokenId);
  }

  // 上架nft - 成功
  // forge test --mt test_nftMint_success --mp ./test/NFTMarketTest/NFTMarket.t.sol -vvvvv
  function test_nftMint_success() public {
    test_erc20Transfer();
    (uint256 upAmount, uint256 tokenId) = test_nftMint();
    vm.startPrank(suzefeng);
      nft721.tokenURI(tokenId); // 查找是否有此tokenId
      nft721.approve(address(market), tokenId); // 把tokenId 授权给market

      // 上架事件
      vm.expectEmit();
      emit NFTMarket.Listed(suzefeng, tokenId, upAmount);

      market.list(tokenId, upAmount);

      (uint256 price, address seller) = market.listings(tokenId);

      // 上架价格应该等于 (我设置的上架价格 = upAmount)
      assertEq(price, upAmount, "Listing price should be upAmount");
      assertEq(seller, suzefeng, "Seller should be suzefeng");
      assertEq(nft721.ownerOf(tokenId), address(market), "NFT should be transferred to market");
    vm.stopPrank();
  }

  // 上架nft - 失败, 不知道模拟什么失败,随便搞一个吧
  // forge test --mt test_nftMint_fail --mp ./test/NFTMarketTest/NFTMarket.t.sol -vvvvv
  function test_nftMint_fail() public {
    test_erc20Transfer();
    (uint256 upAmount, uint256 tokenId) = test_nftMint();
    vm.startPrank(suzefeng);
      nft721.tokenURI(tokenId); // 查找是否有此tokenId
      nft721.approve(address(market), tokenId); // 把tokenId 授权给market

      // 上架事件
      vm.expectEmit();
      emit NFTMarket.Listed(suzefeng, tokenId, upAmount);
      
      market.list(tokenId, upAmount);

      (uint256 price, address seller) = market.listings(tokenId);

      // 上架价格应该等于 (我设置的上架价格 = upAmount)
      vm.expectRevert();
      assertEq(price, upAmount, "Listing price should be upAmount"); // 可模拟失败 - 
      assertEq(makeAddr("otherPeople"), suzefeng, "Seller should be suzefeng"); // 模拟失败 - 卖家不是suzefeng
      assertEq(nft721.ownerOf(tokenId), address(market), "NFT should be transferred to market"); // 可模拟失败 - 
    vm.stopPrank();
  }
  // 自己购买NFT
  // forge test --mt test_buyNft_myself --mp ./test/NFTMarketTest/NFTMarket.t.sol -vvvvv
  function test_buyNft_myself() public {
    test_erc20Transfer();
    (uint256 upAmount, uint256 tokenId) = test_nftMint();
    vm.startPrank(suzefeng);
      nft721.tokenURI(tokenId); // 查找是否有此tokenId
      nft721.approve(address(market), tokenId); // 把tokenId 授权给market

      market.list(tokenId, upAmount);

      (uint256 price, address seller) = market.listings(tokenId);

      token.approve(address(market), upAmount);

      // vm.expectEmit();
      // emit NFTMarket.Purchased(suzefeng, tokenId, upAmount);

      vm.expectRevert();
      market.buyNFT(suzefeng ,tokenId);

    vm.stopPrank();
  }

  // forge test --mt test_buyNft_duplicate --mp ./test/NFTMarketTest/NFTMarket.t.sol -vvvvv
  function test_buyNft_duplicate() public {
    address alice = makeAddr("alice");
    token.transfer(alice, 1000 ether); // 给alice充钱
    token.transfer(suzefeng, 1000 ether); // 给alice充钱
    
    vm.startPrank(suzefeng);
      uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
      nft721.approve(address(market), tokenId);
      market.list(tokenId, 99);
    vm.stopPrank();

    vm.startPrank(alice);
      token.balanceOf(alice);
      token.approve(address(market), 1000); // TODO 不需要授权, 使用 paymentToken.transferWithCallback
      market.buyNFT(alice, tokenId);

      vm.expectRevert();
      market.buyNFT(alice, tokenId);
    vm.stopPrank();

  }
  // 支付Token过少情况
  // forge test --mt test_buyNft_moreAmount --mp ./test/NFTMarketTest/NFTMarket.t.sol -vvvvv
  function test_buyNft_moreAmount() public {
    address alice = makeAddr("alice");
    token.transfer(alice, 100 ether); // 给alice充钱
    token.transfer(suzefeng, 100 ether); // 给alice充钱

    (uint256 tokenId) = nft721.mint(alice, "tokenURI");
    vm.startPrank(alice);
      nft721.tokenURI(tokenId); // 查找是否有此tokenId
      nft721.approve(address(market), tokenId); // 把tokenId 授权给market

      market.list(tokenId, 100000000 ether);

      // (uint256 price, address seller) = market.listings(tokenId);

    vm.stopPrank();


    vm.startPrank(suzefeng);
      token.balanceOf(suzefeng);
      token.approve(address(market), 1000000);
      vm.expectRevert();
      market.buyNFT(suzefeng ,tokenId);

      // vm.expectEmit();
      // emit NFTMarket.Purchased(suzefeng, tokenId, 10000 ether);
    vm.stopPrank();
    
  }

  // TODO 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
  // forge test --mt test_fuzz_listAndBuyNFT --mp ./test/NFTMarketTest/NFTMarket.t.sol -vvvvv
  // function test_fuzz_listAndBuyNFT() public {
  //     // 安全性问题: 随机数是时间戳(block.timestamp)生成, 
  //     // 使用 chainlink vrf (https://docs.chain.link/vrf/v2-5/best-practices)
  //     // 暂时先用不安全的吧  没时间搞了

  //     uint256 randomPrice = uint256(keccak256(abi.encodePacked(block.timestamp))) % 10000 + 1;
  //     uint256 tokenId = nft721.mint(suzefeng, "tokenURI");
  //     vm.prank(suzefeng);
  //     market.list(tokenId, randomPrice);

  //     // address randomBuyer = makeAddr("randomBuyer");
  //     // vm.prank(randomBuyer);
  //     // token.approve(address(market), randomPrice);
  //     // vm.prank(randomBuyer);
  //     // market.buyNFT(tokenId);

  //     // assertEq(nft721.ownerOf(tokenId), randomBuyer, "NFT should be transferred to randomBuyer");
  //   }

    // TODO 「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
}
