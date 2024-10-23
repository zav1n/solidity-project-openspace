pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract DecertERC721 is ERC721URIStorage {
uint256 private _tokenIds;
constructor(string memory name, string memory token) ERC721(name,token) {}

    function mint(address student, string memory tokenURI) public returns (uint256) {
        _tokenIds++;

        _mint(student, _tokenIds);
        _setTokenURI(_tokenIds, tokenURI);

        return _tokenIds;
    }
}