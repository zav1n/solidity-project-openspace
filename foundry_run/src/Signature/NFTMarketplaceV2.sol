// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TokenPermitERC20.sol";

contract NFTMarketplaceV2 is 
  IERC721Receiver,
  EIP712("testNFT", "1")
{
    using ECDSA for bytes32;

    TokenPermit public paymentToken;
    ERC721 public nft721;
    address public owner;

    mapping(address => bool) public whitelist;
    bytes32 private immutable PERMIT_BUY_HASH = keccak256(
      abi.encodePacked("PermitBuy(address buyer,address market,uint256 tokenId,uint256 deadline)")
    );
    bytes32 private immutable PERMIT_LIST_HASH = keccak256(
      abi.encodePacked("PermitList(address seller,uint256 tokenId,uint256 price)")
    );
    mapping(address => uint256) public nonces;

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

    modifier onlyOwner {
      require(msg.sender == owner, "only owner can be execute");
      _;
    }
    function initialize(
      address _tokenAddress,
      address _nft721,
      address _owner
    ) public {
      paymentToken = TokenPermit(_tokenAddress);
      nft721 = ERC721(_nft721);
      owner = _owner;
    }

    // must to be signature and use permitList
    function _list(address seller, uint256 tokenId, uint256 price) internal {
        require(nft721.ownerOf(tokenId) == seller, "You are not the owner");
        require(price > 0, "Price must be greater than zero");

        // Transfer the NFT to the market contract (it will hold the NFT until it's sold)
        nft721.safeTransferFrom(seller, address(this), tokenId);

        // Create listing
        listings[tokenId] = Listing({
            price: price,
            seller: seller
        });

        emit Listed(seller, tokenId, price);
    }

    function permitList(address seller, uint256 tokenId, uint256 price, bytes memory signature) public {
      bytes32 struchHash = keccak256(
        abi.encode(
          PERMIT_LIST_HASH,
          seller,
          tokenId,
          price
        )
      );
      bytes32 sign = keccak256(abi.encodePacked("\x19\x01", getDomain(), struchHash));
      require(seller == ECDSA.recover(sign, signature), "list signature invalid");
      _list(seller, tokenId, price);
    }

    // Buy the NFT by transferring the required token amount
    function buyNFT(address buyer,uint256 tokenId) public {
      Listing memory listing = listings[tokenId];
      require(listing.price > 0, "NFT is not listed");
      require(buyer != listing.seller, "don't buy youself nft");
      require(paymentToken.balanceOf(buyer) > listing.price, "not enought amount");
      
      // Transfer the required payment tokens from the buyer to the seller
      // paymentToken.transferWithCallback(msg.sender, listing.price);
      paymentToken.transferFrom(buyer, listing.seller, listing.price);
      

      // Transfer the NFT to the buyer
      nft721.safeTransferFrom(address(this), buyer, tokenId);

      // Remove the listing
      delete listings[tokenId];

      emit Purchased(buyer, tokenId, listing.price);
    }

    function permitBuy(
      uint256 tokenId,
      uint256 nonce,
      uint256 deadline,
      uint8 v, 
      bytes32 r, 
      bytes32 s
    ) public {
      // Checke exceeeded deadline
      require(block.timestamp <= deadline, "Signature expired");

      // Checke valid nonce
      uint256 currentNonce = nonces[msg.sender];
      require(currentNonce == nonce, "Invalid nonce");

      // valid whitelist
      bool isValid = verifySignature( tokenId,nonce,deadline,v, r, s );
      require(isValid, "you'r not have whitelist");
      
      // increase buyer nonce, Prevent reuse
      nonces[msg.sender]++;

      buyNFT(msg.sender, tokenId);
    }

    function permitListAndBuy(address seller, uint256 tokenId, uint256 price, bytes memory signature) public {
      // require(!listings[tokenId], "already list");
      permitList(seller, tokenId, price, signature);
      buyNFT(msg.sender, tokenId);
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
        nft721.safeTransferFrom(address(this), from, tokenId);

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

    // valid whitelist
    // verify signature of permitBuy
    function verifySignature(
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 structHash = getPermitBuyHash(
            msg.sender,
            address(this),
            tokenId,
            nonce,
            deadline
        );
        bytes32 sign = keccak256(abi.encodePacked("\x19\x01", getDomain(), structHash));
        address signer = ECDSA.recover(sign, v, r, s);
        require(signer == owner, "Invalid signature");
        return owner == signer;
    }


    function getPermitBuyHash(
        address buyer,
        address market,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_BUY_HASH,
                buyer,
                market,
                tokenId,
                nonce,
                deadline
            )
        );

        // origin EIP712 
        return _hashTypedDataV4(structHash);
        
    }

    function getDomain() public view returns (bytes32) {
        return _domainSeparatorV4();
    }
}