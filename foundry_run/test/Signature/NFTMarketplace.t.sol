pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/Signature/TokenPermitERC20.sol";
import "@src/Signature/TokenBank.sol";
import "@src/Signature/NFTMarketplace.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";

contract TokenBankNFTMarketTest is Test {
    TokenPermit token;
    TokenBank tokenBank;
    NFTMarketplace nftMarket;
    DecertERC721 nft721;
    address owner;
    address addr1;
    address addr2;

    function setUp() public {
        owner = address(this);
        addr1 = address(0x1);
        addr2 = address(0x2);

        token = new TokenPermit("test", "TTT", (10 ** 10) * 10 ** 18);
        tokenBank = new TokenBank();
        nft721 = new DecertERC721("SeafoodMarket", "SFM");
        nftMarket = new NFTMarketplace(address(token), address(nft721), "testNFT", "1");

        // Mint tokens to addr1 for testing
        token.transfer(addr1, 10000 * 10 ** 18);
    }

    function testPermitDeposit() public {
        uint256 amount = 10 * 10 ** 18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(addr1);
        
        // Create the permit signature
        bytes32 permitHash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
            addr1,
            address(tokenBank),
            amount,
            nonce,
            deadline
        ));

        bytes32 signatureHash = keccak256(abi.encodePacked(
            "\x19\x01",
            token.DOMAIN_SEPARATOR(),
            permitHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, signatureHash); // Sign as addr1

        // Allow addr1 to deposit using permit
        vm.startPrank(addr1);
        tokenBank.permitDeposit(token, addr1, amount, deadline, v, r, s);
        uint256 balance = tokenBank.getBalance(token, addr1);
        assertEq(balance, amount, "Deposit amount should match");
        vm.stopPrank();
    }

    function test_mint() public {
        address alice = makeAddr("alice");
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
            nftMarket.buyNFT(tokenId);
        vm.stopPrank();

        token.balanceOf(bob);


    }
    function test_PermitBuy() public {
        uint256 tokenId = 1;
        uint256 amount = 50 * 10 ** 18;
        uint256 deadline = block.timestamp + 1 hours;

        // Approve token transfer to NFTMarketplace
        vm.startPrank(addr1);
        token.approve(address(nftMarket), amount);
        vm.stopPrank();

        // Create a signature for whitelisting
        bytes32 permitHash = keccak256(abi.encode(
            keccak256("Permit(address buyer,uint256 tokenId,uint256 amount,uint256 deadline)"),
            addr1,
            tokenId,
            amount,
            deadline
        ));

        bytes32 signatureHash = keccak256(abi.encodePacked(
            "\x19\x01",
            nftMarket.DOMAIN_SEPARATOR(),
            permitHash
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, signatureHash); // Sign as owner

        address singer = ecrecover(permitHash, v, r, s);
        
        assertEq(singer == addr1, true);

        // Allow purchase using permit
        vm.startPrank(addr1);
        nftMarket.permitBuy(addr1, tokenId, amount, deadline, v, r, s);
        vm.stopPrank();

        // Check if the NFT is owned by addr1
        assertEq(nft721.ownerOf(tokenId), addr1, "NFT should be owned by addr1");
    }
}