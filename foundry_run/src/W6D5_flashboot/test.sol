// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract OpenspaceNFT {
    bool public presaleActive = false;
    address public owner;
    mapping(address => bool) public presaleWhitelist;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function startPresale() external onlyOwner {
        presaleActive = true;
    }

    function participateInPresale() external  view{
        require(presaleActive, "Presale is not active");
        require(presaleWhitelist[msg.sender], "Not whitelisted");
        // Logic for participating in presale
    }

    function addToWhitelist(address _address) external onlyOwner {
        presaleWhitelist[_address] = true;
    }
}