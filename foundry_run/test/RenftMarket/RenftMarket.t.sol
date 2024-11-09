// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";
import { RenftMarket } from "@src/RenftMarket/RenftMarket.sol";

contract RenftMarketTest is Test {
  DecertERC721 public nft721;
  RenftMarket public market;

  address alice;
  uint256 private alicePk;

  address bob;

  function setUp() public {
    nft721 = new DecertERC721("SeafoodMarket", "SFM");
    market = new RenftMarket();
    alicePk = uint256(keccak256(abi.encodePacked("alice")));
    alice = vm.addr(alicePk);
    bob = makeAddr("bob");
    vm.deal(bob, 100 ether);

    nft721.mint(alice, "abcd001");
    nft721.mint(alice, "abcd002");
    nft721.mint(alice, "abcd003");

    vm.prank(alice);
    nft721.approve(address(market), 1);
  }

  function test_order() public returns(RenftMarket.RentoutOrder memory, bytes memory, bytes32){
    RenftMarket.RentoutOrder memory order = RenftMarket.RentoutOrder({
      maker: alice,
      nft_ca: address(nft721),
      token_id: 1,
      daily_rent: 0.00001 ether,
      max_rental_duration: 1735574400, // 2024-12-31
      min_collateral: 0.01 ether,
      list_endtime: 1735574400 // 2024-12-31
    });
    bytes32 hashStruct = market.getOrderHash(order);

    bytes32 permitHash = keccak256(abi.encodePacked("\x19\x01", market.getDomain(), hashStruct));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, permitHash);
    bytes memory signature = bytes.concat(r, s, bytes1(v));
    return(order, signature, hashStruct);
  }

  function test_borrow() public {
    // 一开始NFT是alice的
    assertEq(nft721.ownerOf(1), alice);

    (RenftMarket.RentoutOrder memory order, bytes memory signature, bytes32 orderHash) = test_order();

    vm.expectEmit(true, true, true, true);
    emit RenftMarket.BorrowNFT(bob, order.maker, orderHash, 0.1 ether);

    // bob租alice的tokenId = 1 的nft
    vm.prank(bob);
    market.borrow{ value: 0.1 ether }(order, signature);


    // 检查nft是否成功租(转)给bob
    assertEq(nft721.ownerOf(1), bob);
  }

  
  function cancelOrder() public {
    (RenftMarket.RentoutOrder memory rentoutOrder, bytes memory signature, bytes32 orderHash) = test_order();

    // 30天后
    vm.warp(block.timestamp + 30 days);
    // skip(30 days);

    vm.expectEmit(true, true, true, true);
    emit RenftMarket.OrderCanceled(rentoutOrder.maker, orderHash);


    vm.prank(bob);
    market.cancelOrder(rentoutOrder, signature);


  }
}
