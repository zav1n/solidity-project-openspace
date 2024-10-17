// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseERC20 } from "./BaseERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";



contract NFTMarket is IERC721Receiver {
    using Address for address;

    // ERC20 token contract (our custom extended token)
    BaseERC20 public paymentToken;

    // NFT contract
    IERC721 public nftContract;

    // Listing information
    struct Listing {
        uint256 price;      // Price in ERC20 tokens
        address seller;     // The owner who listed the NFT
    }

    // Mapping from NFT ID to its listing info
    mapping(uint256 => Listing) public listings;

    // Event for listing
    event Listed(address indexed seller, uint256 indexed tokenId, uint256 price);
    
    // Event for purchase
    event Purchased(address indexed buyer, uint256 indexed tokenId, uint256 price);

    // Constructor: initialize the ERC20 token and NFT contract
    constructor(address _paymentToken, address _nftContract) {
        paymentToken = BaseERC20(_paymentToken);
        nftContract = IERC721(_nftContract);
    }

    // List NFT on the market
    function list(uint256 tokenId, uint256 price) external {
        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(price > 0, "Price must be greater than zero");

        // Transfer the NFT to the market contract (it will hold the NFT until it's sold)
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);

        // Create listing
        listings[tokenId] = Listing({
            price: price,
            seller: msg.sender
        });

        emit Listed(msg.sender, tokenId, price);
    }

    // Buy the NFT by transferring the required token amount
    function buyNFT(address buyer,uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "NFT is not listed");
        require(buyer != listing.seller, "don't buy youself nft");
        require(paymentToken.balanceOf(buyer) > listing.price, "not enought amount");
        
        // Transfer the required payment tokens from the buyer to the seller
        // paymentToken.transferWithCallback(msg.sender, listing.price);
        paymentToken.transferFrom(msg.sender, listing.seller, listing.price);
        

        // Transfer the NFT to the buyer
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);

        // Remove the listing
        delete listings[tokenId];

        emit Purchased(msg.sender, tokenId, listing.price);
    }

    // Handle receiving tokens, this function is triggered by ERC20 transfer
    function tokensReceived(
        address from,
        address to,
        uint256 amount,
        bytes calldata userData
    ) external {
        require(msg.sender == address(paymentToken), "Only the ERC20 token contract can call this");

        uint256 tokenId = abi.decode(userData, (uint256));  // The tokenId of the NFT to buy
        Listing memory listing = listings[tokenId];
        
        require(listing.price > 0, "NFT is not listed for sale");
        require(amount == listing.price, "Incorrect payment amount");

        // Transfer NFT to the buyer
        nftContract.safeTransferFrom(address(this), from, tokenId);

        // Transfer the tokens to the seller
        paymentToken.transfer(listing.seller, amount);

        // Remove the listing
        delete listings[tokenId];

        emit Purchased(from, tokenId, amount);
    }

    // Required for receiving NFTs
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}