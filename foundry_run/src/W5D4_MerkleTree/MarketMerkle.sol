// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract MarketMerkle is IERC721Receiver {
    IERC20 public token;
    IERC721 nft721;

    bytes32 public merkleRoot;

    mapping(uint256 => Listing) public listings;
    mapping(address => bool) public hasClaimed;

    struct Listing {
      address seller;
      uint256 price;
    }

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    // event NFTPurchased(uint256 indexed tokenId, address indexed buyer, uint256 price);

    constructor(address _token, address _nft721, bytes32 _merkleRoot) {
        token = IERC20(_token);
        nft721 = IERC721(_nft721);
        merkleRoot = _merkleRoot;
    }
    function list(uint256 tokenId, uint256 price ) public {

        require(price > 0, "This NFT is not for sale.");

        require(nft721.ownerOf(tokenId) == msg.sender,"Not the owner");

        require(
          nft721.isApprovedForAll(msg.sender, address(this)) || 
          nft721.getApproved(tokenId) == address(this), 
          "NFT not approved"
        );

        listings[tokenId] = Listing({seller: msg.sender,price: price});
        emit NFTListed(tokenId, msg.sender, price);
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
        ERC20Permit(address(token)).permit(owner, spender, value, deadline, v, r, s);
    }

    function claimNFT(
        uint256 tokenId,
        uint256 price,
        bytes32[] calldata proof
    ) external {
        require(!hasClaimed[msg.sender], "Already claimed");
        require(_verifyWhitelist(msg.sender, proof), "Invalid proof");

        uint256 discountedPrice = price / 2;
        require(token.transferFrom(msg.sender, address(this), discountedPrice), "Token transfer failed");
        
        hasClaimed[msg.sender] = true;
    }

    function multicall(
        bytes memory permitCallData,
        bytes memory claimNFTCallData
    ) external {
        (bool permitSuccess, ) = address(this).delegatecall(permitCallData);
        require(permitSuccess, "Permit failed");

        (bool claimSuccess, ) = address(this).delegatecall(claimNFTCallData);
        require(claimSuccess, "ClaimNFT failed");
    }

    function _verifyWhitelist(address account, bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // This contract accepts all ERC721 tokens
        return this.onERC721Received.selector;
    }
}
