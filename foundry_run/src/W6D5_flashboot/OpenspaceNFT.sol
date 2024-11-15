// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OpenspaceNFT is ERC721, Ownable {
    bool public isPresaleActive = true;
    uint256 public nextTokenId;

    constructor() ERC721("OpenspaceNFT", "OSNFT") Ownable(msg.sender) {
        nextTokenId = 1;
    }

    function presale(uint256 amount) external payable {
        require(isPresaleActive, "Presale is not active");
        require(msg.sender != owner(), "Disabled for owner");
        require(amount * 0.01 ether == msg.value, "Invalid amount");
        require(amount + nextTokenId <= 1024, "Not enough tokens left");

        uint256 _nextId = nextTokenId;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _nextId);
            _nextId++;
        }
        nextTokenId = _nextId;
    }

    function enablePresale() external onlyOwner {
        isPresaleActive = true;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Transfer failed");
    }
}