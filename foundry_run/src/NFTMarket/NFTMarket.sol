// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract NFTMarket {
    IERC20 token;
    IERC721 nft721;
    
    struct NFTList{
        address seller;
        uint256 amount;
    }

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