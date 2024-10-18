// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// import "./erc20.sol";
// import "./BaseERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

contract NFTMarket {
    IERC20 token;
    IERC721 nft721;
    
    struct NFTList{
        address seller;
        uint256 amount;
    }

    // NFTList[] userList;
    mapping(uint256 => NFTList) public tokenIds;
    

    constructor(IERC20 tokenAddress, IERC721 NFTAddress) {
        token = tokenAddress;
        nft721 = NFTAddress;
    }

    function list(uint256 tokenId, uint256 amount) public {
        // 是否是nft持有者
        require(msg.sender == nft721.ownerOf(tokenId), "you isn't Nft holder");
        require(amount > 0, "Put on shelves amount not zero");
        tokenIds[tokenId] = NFTList({ seller: msg.sender, amount: amount });

    }

    function buyNFT(uint256 tokenId) public {
        NFTList memory nft = tokenIds[tokenId];
        require(nft.seller != address(0), "unissued nft");

        token.transferFrom(msg.sender, nft.seller, nft.amount);
        nft721.safeTransferFrom(nft.seller, msg.sender, tokenId);
        
        delete tokenIds[tokenId];
    }

}