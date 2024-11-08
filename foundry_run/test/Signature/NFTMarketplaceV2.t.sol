pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/Signature/TokenPermitERC20.sol";
import "@src/Signature/NFTMarketplaceV2.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";


contract TokenBankNFTMarketTest is Test {
    TokenPermit token;
    NFTMarketplaceV2 nftMarketV2;
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
        nftMarketV2 = NFTMarketplaceV2(address(proxy));

        // Upgrades.upgradeProxy(
        //     address(proxy),
        //     "NFTMarketplaceV3.sol",
        //     abi.encodeCall(NFTMarketplaceV3.initialize, (address(token), address(nft721), deployer))
        // );
        // nftMarketV3 = NFTMarketplaceV3(address(proxy));
    }

    function test_initialize() public {
        assertEq(nftMarketV2.owner(), deployer);
        assertEq(address(nftMarketV2.paymentToken()), address(token));
        assertEq(address(nftMarketV2.nft721()), address(nft721));
    }

    function test_mint() public {
        uint256 tokenId = nft721.mint(alice, "abcd");
        nft721.tokenURI(tokenId); // 查找是否有此tokenId

    }
    
    function test_permitList_success() public returns(uint256){
        uint256 bobPrivateKey = uint256(keccak256(abi.encodePacked("bob")));
        address bob = vm.addr(bobPrivateKey);
        uint256 tokenId = nft721.mint(bob, "abcd001");
        uint256 price = 1 ether;

        vm.prank(bob);
        nft721.setApprovalForAll(address(nftMarketV2), true);

        address seller = bob;
        bytes32 domain = nftMarketV2.getDomain();
        bytes32 structHash = keccak256(abi.encode(
            keccak256(abi.encodePacked("PermitList(address seller,uint256 tokenId,uint256 price)")),
            seller,
            tokenId,
            price
        ));
        bytes32 permitHash = keccak256(abi.encodePacked("\x19\x01", domain, structHash));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPrivateKey, permitHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));
        vm.prank(bob);
        nftMarketV2.permitList(seller, tokenId, price, signature);
        (uint256 nftPrice, address sellor) = nftMarketV2.listings(1);
        assertEq(sellor, bob);
        assertEq(nftPrice, price);
        return tokenId;
    }

    function test_permitBuy_success() public {

        token.transfer(alice, 99999 ether);

        // bob(user) successfully listed, then proceed with the operation
        uint256 tokenId = test_permitList_success();
        uint256 nonce = nftMarketV2.nonces(alice);
        uint256 deadline = block.timestamp + 1 days;
        
        // project party sign alice
        vm.prank(deployer);
        (uint8 v, bytes32 r, bytes32 s) = projectSignWhiteList(alice, tokenId, nonce, deadline);

        // alice(buyer) buy NFT
        vm.startPrank(alice);
          token.approve(address(nftMarketV2), 99999 ether);
          nftMarketV2.permitBuy(
              tokenId,
              nonce,
              deadline,
              v,
              r,
              s
          );
        vm.stopPrank();

    }

    function test_permitListAndBuy_success() public {
        uint256 bobPrivateKey = uint256(keccak256(abi.encodePacked("bob")));
        address bob = vm.addr(bobPrivateKey);

        address clavin = makeAddr("clavin");
        token.transfer(clavin, 99999 ether);
        vm.prank(clavin);
        token.approve(address(nftMarketV2), 99999 ether);

        uint256 tokenId = nft721.mint(bob, "abcd001");
        uint256 price = 100 ether;
        address seller = bob;

        vm.prank(bob);
        nft721.setApprovalForAll(address(nftMarketV2), true);

        bytes32 domain = nftMarketV2.getDomain();
        bytes32 structHash = keccak256(abi.encode(
            keccak256(abi.encodePacked("PermitList(address seller,uint256 tokenId,uint256 price)")),
            seller,
            tokenId,
            price
        ));
        bytes32 permitHash = keccak256(abi.encodePacked("\x19\x01", domain, structHash));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPrivateKey, permitHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));


        vm.prank(clavin);
        nftMarketV2.permitListAndBuy(bob, tokenId, price, signature);

        // 查询nft是否clavin
        assertEq(nft721.ownerOf(tokenId), clavin);
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
        
        bytes32 doamin = nftMarketV2.getDomain();
        bytes32 structHash = nftMarketV2.getPermitBuyHash(
            buyer,
            address(nftMarketV2),
            tokenId,
            nonce,
            deadline
        );
        bytes32 signatureWL = keccak256(abi.encodePacked("\x19\x01", doamin, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, signatureWL);
        return(v, r, s);
    }

}