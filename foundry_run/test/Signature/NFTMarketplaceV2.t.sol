pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/Signature/TokenPermitERC20.sol";
import "@src/Signature/NFTMarketplaceV2.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract TokenBankNFTMarketTest is Test {
    TokenPermit token;
    NFTMarketplaceV2 nftMarket;
    DecertERC721 nft721;
    ERC1967Proxy proxy;
    address deployer;
    uint256 private ownerPrivateKey;
    address alice = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    address[] private whiteList = [alice];

    function setUp() public {
        ownerPrivateKey = uint256(keccak256(abi.encodePacked("owner")));
        deployer = vm.addr(ownerPrivateKey);
        

        token = new TokenPermit("test", "TTT", (10 ** 10) * 10 ** 18);
        nft721 = new DecertERC721("SeafoodMarket", "SFM");
        NFTMarketplaceV2 impl = new NFTMarketplaceV2();
        
        proxy = new ERC1967Proxy(
          address(impl),
          abi.encodeCall(impl.initialize, (address(token), address(nft721), deployer))
        );
        nftMarket = NFTMarketplaceV2(address(proxy));
    }

    function test_initialize() public {
        assertEq(nftMarket.owner(), deployer);
        assertEq(address(nftMarket.paymentToken()), address(token));
        assertEq(address(nftMarket.nft721()), address(nft721));
    }
    function test_mint() public {
        uint256 tokenId = nft721.mint(alice, "abcd");
        nft721.tokenURI(tokenId); // 查找是否有此tokenId

    }
    
    function test_permitList_success() public returns(uint256){
        uint256 bobPrivateKey = uint256(keccak256(abi.encodePacked("bob")));
        address bob = vm.addr(bobPrivateKey);
        // token.transfer(bob, 99999 ether);
        uint256 tokenId = nft721.mint(bob, "abcd001");
        uint256 price = 1 ether;

        vm.prank(bob);
        nft721.setApprovalForAll(address(nftMarket), true);


        bytes32 domain = nftMarket.getDomain();
        bytes32 structHash = keccak256(abi.encode(
            keccak256(abi.encodePacked("PermitList(uint256 tokenId, uint256 price)")),
            tokenId,
            price
        ));
        bytes32 permitHash = keccak256(abi.encodePacked("\x19\x01", domain, structHash));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPrivateKey, permitHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));
        vm.prank(bob);
        nftMarket.permitList(tokenId, price, signature);
        (uint256 nftPrice, address seller) = nftMarket.listings(1);
        assertEq(seller, bob);
        assertEq(nftPrice, price);
        return tokenId;
    }

    function test_permitBuy_success() public {

        token.transfer(alice, 99999 ether);

        // bob(user) successfully listed, then proceed with the operation
        uint256 tokenId = test_permitList_success();
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
        bytes32 structHash = nftMarket.getPermitBuyHash(
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