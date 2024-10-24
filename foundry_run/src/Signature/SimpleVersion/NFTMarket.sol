// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MyNFT.sol";

contract NFTMarket {
    MyNFT public nft;
    IERC20 public token;
    address public projectOwner;
    mapping(bytes32 => bool) public usedSignatures;

    constructor(MyNFT _nft, IERC20 _token) {
        nft = _nft;
        token = _token;
        projectOwner = msg.sender;
    }

    // 使用白名单签名进行购买
    function permitBuy(
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Signature expired");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, tokenId, price, deadline));
        require(!usedSignatures[hash], "Signature already used");

        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address signer = ecrecover(message, v, r, s);
        require(signer == projectOwner, "Invalid signature");

        usedSignatures[hash] = true;

        require(token.transferFrom(msg.sender, projectOwner, price), "Payment failed");
        nft.safeTransferFrom(projectOwner, msg.sender, tokenId);
    }
}