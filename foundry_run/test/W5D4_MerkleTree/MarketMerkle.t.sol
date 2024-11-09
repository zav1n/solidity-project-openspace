pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { MarketMerkle, Multicall } from "@src/W5D4_MerkleTree/MarketMerkle.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@src/Signature/TokenPermitERC20.sol";

contract ValidMerkleTest is Test {
    MarketMerkle market;
    TokenPermit token;
    Multicall multicall;
    // 从merklet.ts文件获取的root
    bytes32 merkleRoot = bytes32(0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097);
    Account alice = makeAccount("alice");
    address suzefeng = address(0x1234567890000000000000000000000987654321);

    function setUp() public {
        token = new TokenPermit("MTK", "MTK", 1_000_000_000 ether);
        market = new MarketMerkle(token, merkleRoot);
        multicall = new Multicall();

        token.transfer(alice.addr, 200000 ether);
    }

    function test_verifyWhitelist() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb);
        proof[1] = bytes32(0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c);
        bool result = market.verifyWhitelist(address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4), proof);
        assertTrue(result);
    }

    function test_multicall() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32(0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb);
        proof[1] = bytes32(0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c);

        uint256 nftTokenId = 1;
        uint256 nftPrice = 10 ether;
        uint256 deadline = block.timestamp + 1 days;
        uint256 nonce = token.nonces(alice.addr);

        bytes32 domainSeparator = token.getDomainSeparator();
        bytes32 hashStruct = keccak256(abi.encode(
            token.getPermitTypehash(),
            alice.addr,
            address(market),
            nftPrice / 2,
            nonce,
            deadline
          ));
        bytes32 permitHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashStruct));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alice.key, permitHash);

        // 验证permit前面是否正确并且成功
        // console.log("start valid signature");
        // market.permitPrePay(alice.addr, address(market), nftPrice / 2, deadline, v, r, s);
        // console.log("pass valid");

        // Prepare multicall data
        bytes memory permitCallData = abi.encodeWithSignature(
            "permitPrePay(address,address,uint256,uint256,uint8,bytes32,bytes32)",
            alice.addr, address(market), nftPrice / 2 , deadline, v, r, s);

        bytes memory claimNFTCallData = abi.encodeWithSignature(
            "claimNFT(uint256,uint256,bytes32[])",
            nftTokenId, nftPrice, proof
        );

        // Execute multicall
        vm.prank(alice.addr);
        multicall.execute(
            address(market),
            permitCallData,
            claimNFTCallData
        );

        // // Assertions
        // assertEq(market.ownerOf(nftTokenId), alice.addr, "NFT not claimed correctly");
        // assertEq(token.balanceOf(alice.addr), 100 * 10**18, "Incorrect token balance after purchase");
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