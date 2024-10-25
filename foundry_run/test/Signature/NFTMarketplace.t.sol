pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/Signature/TokenPermitERC20.sol";
import "@src/Signature/NFTMarketplace.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";


contract TokenBankNFTMarketTest is Test {
    TokenPermit token;
    NFTMarketplace nftMarket;
    DecertERC721 nft721;
    address owner;
    uint256 private ownerPrivateKey;
    address alice = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);

    function setUp() public {
        ownerPrivateKey = uint256(keccak256(abi.encodePacked("owner")));

        token = new TokenPermit("test", "TTT", (10 ** 10) * 10 ** 18);
        nft721 = new DecertERC721("SeafoodMarket", "SFM");
        nftMarket = new NFTMarketplace(address(token), address(nft721), "testNFT");


    }

    function test_mint() public {
        address bob = makeAddr("bob");
        token.transfer(bob, 99999 ether);

        uint256 tokenId = nft721.mint(alice, "abcd");
        nft721.tokenURI(tokenId); // 查找是否有此tokenId

        vm.startPrank(alice);
            nft721.approve(address(nftMarket), tokenId);
            nftMarket.list(tokenId, 1000 ether);
            (uint256 price, address seller) = nftMarket.listings(tokenId);
        vm.stopPrank();

        vm.startPrank(bob);
            // nft721.approve(address(nftMarket), tokenId);
            token.approve(address(nftMarket), 99999 ether);
            nftMarket.buyNFT(bob, tokenId);
        vm.stopPrank();

        token.balanceOf(bob);

    }
    
    function test_mintAndListing() public returns(uint256 tokenId){
        uint256 id = nft721.mint(alice, "ipfs://abcdefghijklnmopqrstuvwxyz0123456789");
        
        uint256 listingPrice = 1000 ether;
        vm.startPrank(alice);
            nft721.approve(address(nftMarket), id);
            nftMarket.list(id, listingPrice);
            (uint256 price, address seller) = nftMarket.listings(id);
            assertEq(listingPrice, price);
            assertEq(alice, seller);
        vm.stopPrank();
        
        return id;
    }
    function test_PermitBuy() public {
        // if don't that to get tokenId, you will be to see a disgusting "Stack too deep" error
        uint256 tokenId = test_mintAndListing();

        uint256 buyerPrivateKey = uint256(keccak256(abi.encodePacked("buyer")));
        address buyer = vm.addr(buyerPrivateKey);

        token.transfer(buyer, 99999 ether);

        uint256 nonce = nftMarket.nonces(buyer);
        uint256 deadline = block.timestamp + 1 days;
        

        // 项目方签名
        bytes32 doamin = nftMarket.getDomain();
        bytes32 structHash = nftMarket.getPermitTypeHash(
            buyer,
            address(nftMarket),
            tokenId,
            nonce,
            deadline
        );

        bytes32 signatureWL = keccak256(abi.encodePacked("\x19\x01", doamin, structHash));

        // 用户签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, signatureWL);

        // 
        vm.startPrank(buyer);
            token.approve(address(nftMarket), 99999 ether);
            nftMarket.permitBuy(
                buyer,
                tokenId,
                nonce,
                deadline,
                v,
                r,
                s,
                signatureWL
            );
        vm.stopPrank();
    }
}