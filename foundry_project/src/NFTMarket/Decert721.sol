pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "src/library/Counters.sol";

// old use counters
// contract MyERC721 is ERC721URIStorage {
// using Counter for Counter.Counter;
// Counter.Counter private _tokenIds;

// constructor() ERC721(unicode"suzefeng", "SZF") {}

//     function mint(address student, string memory tokenURI) public returns (uint256) {
//         _tokenIds.increment();

//         uint256 newItemId = _tokenIds.number;
//         _mint(student, newItemId);
//         _setTokenURI(newItemId, tokenURI);

//         return newItemId;
//     }
// }

contract DecertERC721 is ERC721URIStorage {
uint256 private _tokenId;

constructor(string memory name, string memory token) ERC721(name, token) {}

    function mint(address student, string memory tokenURI) public returns (uint256) {
        _tokenId += 1;
        _mint(student, _tokenId);
        _setTokenURI(_tokenId, tokenURI);

        return _tokenId;
    }
}