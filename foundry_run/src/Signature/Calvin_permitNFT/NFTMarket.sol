import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../TokenPermitERC20.sol";

import "./IMarket.sol";


contract NFTMarketplace is IERC721Receiver {
    TokenPermit public paymentToken;
    ERC721 public nft721;

    mapping(address => bool) public whitelist;
    bytes32 public _domainSeparator;
    uint256 private _tokenIds;

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

    constructor(address _tokenAddress,address _nft721, string memory name) {
        nft721 = ERC721(_nft721);
        paymentToken = TokenPermit(_tokenAddress);

        _domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // List NFT on the market
    function list(uint256 tokenId, uint256 price) external {
        require(nft721.ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(price > 0, "Price must be greater than zero");

        // Transfer the NFT to the market contract (it will hold the NFT until it's sold)
        nft721.safeTransferFrom(msg.sender, address(this), tokenId);

        // Create listing
        listings[tokenId] = Listing({
            price: price,
            seller: msg.sender
        });

        emit Listed(msg.sender, tokenId, price);
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

    function permitBuy(uint nftTokenId, IMarket.WhiteList memory whiteList, uint8 v, bytes32 r, bytes32 s) public {
        //verify
        require(verify(whiteList,v,r,s),"invalid white list");
        //check in list
        for(uint i = 0; i<whiteList.whiteList.length;i++){
            if(whiteList.whiteList[0] == msg.sender){
                //allow to buyNFT
                buyNFT(msg.sender, nftTokenId);
                return;
            }
        }
        revert("you are not in white list");
    }

    function verify(
        IMarket.WhiteList memory whiteList,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator, hashStruct(whiteList))
        );
        //ensure whiteList came from tokenAddress' project launcher
        return ecrecover(digest, v, r, s) == address(this); // TODO
    }

    function hashStruct(IMarket.WhiteList memory whiteList) internal pure returns (bytes32) {
        return
            keccak256(
            abi.encode(
                keccak256("WhiteList(address[] whiteList)"),
                whiteList.whiteList
            )
        );
    }

}