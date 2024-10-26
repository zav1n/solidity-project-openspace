pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/Signature/TokenPermitERC20.sol";
import "@src/Signature/NFTMarketplace.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";


contract TokenBankNFTMarketTest is Test {
    TokenPermit token;
    NFTMarketplace nftMarket;
    DecertERC721 nft721;
    address deployer;
    uint256 private ownerPrivateKey;
    address alice = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    address[] private whiteList = [alice];

    function setUp() public {
        ownerPrivateKey = uint256(keccak256(abi.encodePacked("owner")));
        deployer = vm.addr(ownerPrivateKey);

        vm.startPrank(deployer);
            token = new TokenPermit("test", "TTT", (10 ** 10) * 10 ** 18);
            nft721 = new DecertERC721("SeafoodMarket", "SFM");
            nftMarket = new NFTMarketplace(address(token), address(nft721), "testNFT");
        vm.stopPrank();


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
        address bob = makeAddr("bob");
        uint256 id = nft721.mint(bob, "ipfs://abcdefghijklnmopqrstuvwxyz0123456789");
        
        uint256 listingPrice = 1000 ether;
        vm.startPrank(bob);
            nft721.approve(address(nftMarket), id);
            nftMarket.list(id, listingPrice);
            (uint256 price, address seller) = nftMarket.listings(id);
            assertEq(listingPrice, price);
            assertEq(bob, seller);
        vm.stopPrank();
        
        return id;
    }
    function test_PermitBuy() public {
        // if don't that to get tokenId, you will be to see a disgusting "Stack too deep" error
        uint256 tokenId = test_mintAndListing();

        vm.prank(deployer);
        token.transfer(alice, 99999 ether);

        uint256 nonce = nftMarket.nonces(alice);
        uint256 deadline = block.timestamp + 1 days;
        
        // project party sign alice
        vm.prank(deployer);
        (uint8 v, bytes32 r, bytes32 s) = projectSignWhiteList(alice, tokenId, nonce, deadline);


        // alice(buyer) buy NFT
        vm.startPrank(alice);
            token.approve(address(nftMarket), 99999 ether);
            nftMarket.permitBuy(
                tokenId,
                nonce,
                deadline,
                v,
                r,
                s
            );
        vm.stopPrank();
    }

    // the project party sign the buyer on the whitelist
    function projectSignWhiteList(
        address buyer,
        uint256 tokenId, 
        uint256 nonce, 
        uint256 deadline
    ) public view returns (uint8 v, bytes32 r, bytes32 s){

        // Simulate the signing and judgment of neutral services by the project team
        bool isWhite = false;
        for(uint i = 0; i < whiteList.length; i++){
            if(whiteList[i] == buyer) {
                isWhite = true;
            }
        }
        require(isWhite, "Not on the whitelist");
        
        bytes32 doamin = nftMarket.getDomain();
        bytes32 structHash = nftMarket.getPermitTypeHash(
            buyer,
            address(nftMarket),
            tokenId,
            nonce,
            deadline
        );
        bytes32 signatureWL = keccak256(abi.encodePacked("\x19\x01", doamin, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, signatureWL);
        return(v, r, s);
    }
}