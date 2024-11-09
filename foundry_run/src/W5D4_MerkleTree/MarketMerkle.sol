// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MarketMerkle is ERC721 {
    IERC20 public token;
    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;

    constructor(IERC20 _token, bytes32 _merkleRoot) ERC721("AirdropNFT", "ADNFT") {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function permitPrePay(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        console2.log("-----------------------------------------------------------------------");
        console2.log("-----------------------------------------------------------------------");
        console2.log("-----------------------------------------------------------------------");
        console2.log("-----------------------------------------------------------------------");
        console2.log(owner);
        console2.log(spender);
        console2.log(value);
        console2.log(deadline);
        console2.log(v);
        console2.logBytes32(r);
        console2.logBytes32(s);
        ERC20Permit(address(token)).permit(owner, spender, value, deadline, v, r, s);
    }

    function claimNFT(
        uint256 tokenId,
        uint256 price,
        bytes32[] calldata proof
    ) external {
        require(!hasClaimed[msg.sender], "Already claimed");
        require(verifyWhitelist(msg.sender, proof), "Invalid proof");

        uint256 discountedPrice = price / 2;
        require(token.transferFrom(msg.sender, address(this), discountedPrice), "Token transfer failed");
        
        _safeMint(msg.sender, tokenId);
        hasClaimed[msg.sender] = true;
    }

    // 应该是私有函数内部调用,
    function verifyWhitelist(address account, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}

/**
    !注意
    1. 使用delegatecall时, 状态变量的位置必须保持一致
        不同点在于运行的上下文，B call C，上下文为C；而B delegatecall C，上下文为B。
        目前delegatecall最大的应用是代理合约和EIP-2535 Diamonds（钻石）。
 */
contract Multicall {
    IERC20 public token;
    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;
    constructor() {}

    function execute(
        address target,
        bytes memory permitCallData,
        bytes memory claimNFTCallData
    ) external {
        (bool permitSuccess, ) = target.delegatecall(permitCallData);
        require(permitSuccess, "Permit failed");

        (bool claimSuccess, ) = target.delegatecall(claimNFTCallData);
        require(claimSuccess, "ClaimNFT failed");
    }
}