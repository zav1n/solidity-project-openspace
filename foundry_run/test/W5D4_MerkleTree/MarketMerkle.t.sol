pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { MarketMerkle } from "@src/W5D4_MerkleTree/MarketMerkle.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@src/W5D4_MerkleTree/PermitERC20.sol";

import "@src/DecertERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ValidMerkleTest is Test {
    MarketMerkle market;
    TokenPermit token;
    DecertERC721 nft721;

    uint nftTokenId;
    uint256 nftPrice = 1 ether;

    // 从merklet.ts文件获取的root
    bytes32 merkleRoot = bytes32(0xcab8ba485d057231b1e8c65c05bcfe592c8f9bc592a8b6502d994c65c1ad58be);
    uint256 alicePrivateKey = 0xABCDEF;
    address alice = vm.addr(alicePrivateKey);
    address seller = makeAddr("seller");

    function setUp() public {
        token = new TokenPermit("MTK", "MTK", 1_000_000_000 ether);
        nft721 = new DecertERC721("SeafoodMarket", "SFM");
        market = new MarketMerkle(address(token), address(nft721), merkleRoot);

        token.transfer(alice, 2000 ether);
        nftTokenId = nft721.mint(seller, "nft001abc");

        vm.startPrank(seller);
            nft721.setApprovalForAll(address(market), true);
            market.list(nftTokenId, nftPrice);
        vm.stopPrank();
    }

    function test_verifyMerklet() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0);
        proof[1] = bytes32(0x7e0eefeb2d8740528b8f598997a219669f0842302d3c573e9bb7262be3387e63);
        bytes32 leaf = keccak256(abi.encodePacked(alice));
        bool result =  MerkleProof.verify(proof, merkleRoot, leaf);
        assertTrue(result);
    }

    function test_multicall() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0);
        proof[1] = bytes32(0x7e0eefeb2d8740528b8f598997a219669f0842302d3c573e9bb7262be3387e63);

        uint256 deadline = block.timestamp + 1 days;
        uint256 nonce = token.nonces(alice);

        bytes32 domainSeparator = token.getDomainSeparator();
        bytes32 hashStruct = keccak256(abi.encode(
            token.getPermitTypehash(),
            alice,
            address(market),
            nftPrice / 2,
            nonce,
            deadline
          ));
        bytes32 permitHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashStruct));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, permitHash);

        // 验证permit前面是否正确并且成功
        // console.log("start valid signature");
        // market.permitPrePay(alice, address(market), nftPrice / 2, deadline, v, r, s);
        // console.log("pass valid");

        // Prepare multicall data
        // bytes memory permitCallData = abi.encodeWithSelector(
        //     market.permitPrePay.selector,
        //     alice,
        //     address(market),
        //     nftPrice / 2 ,
        //     deadline,
        //     v,
        //     r,
        //     s
        // );

        // 使用encodeWithSignature
        bytes memory permitCallData = abi.encodeWithSignature(
            "permitPrePay(address,address,uint256,uint256,uint8,bytes32,bytes32)", 
            alice, address(market), nftPrice / 2 , deadline, v, r, s
        );

        // 使用encodeWithSelector
        bytes memory claimNFTCallData = abi.encodeWithSelector(
            market.claimNFT.selector,
            nftTokenId,
            nftPrice,
            proof
        );

        // Execute multicall
        vm.prank(alice);
        market.multicall(
            permitCallData,
            claimNFTCallData
        );

        // // Assertions
        // assertEq(market.ownerOf(nftTokenId), alice, "NFT not claimed correctly");
        // assertEq(token.balanceOf(alice), 100 * 10**18, "Incorrect token balance after purchase");
    }

    // 验证不可重入漏洞
    // function test_Reentrancy() public {
    //     // Prepare Merkle proof for user
    //     bytes32;
    //     proof[0] = keccak256(abi.encodePacked(user));

    //     // Execute claim without multicall to check reentrancy guard
    //     vm.startPrank(user);
    //     market.claimNFT(nftTokenId, nftPrice, proof);
        
    //     // Attempt to claim again and expect revert due to already claimed
    //     vm.expectRevert("Already claimed");
    //     market.claimNFT(nftTokenId, nftPrice, proof);
    // }
}