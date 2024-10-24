pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/Signature/TokenPermitERC20.sol";
import "@src/Signature/TokenBank.sol";
import "@src/Signature/NFTMarketplace.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";

import "@src/Signature/IMarket.sol";

contract TokenBankNFTMarketTest is Test {
    TokenPermit token;
    TokenBank tokenBank;
    NFTMarketplace nftMarket;
    DecertERC721 nft721;
    address owner;
    uint256 private ownerPrivateKey;
    address alice = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    address [] public _whiteList = [alice];

    function setUp() public {
        ownerPrivateKey = uint256(keccak256(abi.encodePacked("owner")));

        token = new TokenPermit("test", "TTT", (10 ** 10) * 10 ** 18);
        tokenBank = new TokenBank();
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
    
    function test_PermitBuy() public returns(IMarket.WhiteList memory ,uint8,bytes32,bytes32){
        // generate EIP-712 domainSeparator
        IMarket.WhiteList memory whiteList = IMarket.WhiteList({
            whiteList: _whiteList
        });

        // generate whiteList hash
        bytes32 whiteListHash = keccak256(abi.encode(
            keccak256("WhiteList(address[] whiteList)"),
            whiteList.whiteList
        ));

        bytes32 premitHash = keccak256(abi.encodePacked("\x19\x01", nftMarket._domainSeparator, whiteListHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, premitHash);
        return (whiteList, v,r,s);
    }
}