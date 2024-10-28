// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MyToken.sol";

contract TokenFactory {
    // 记录已部署的代币合约地址
    mapping(address => bool) public deployedTokens;
    address[] public allTokens;

    // 每次发行的数量
    uint public perMint;

    constructor(uint _perMint) {
        perMint = _perMint;
    }

    // 部署新的 ERC20 代币合约
    function deployInscription(string memory symbol, uint totalSupply) external {
        MyToken newToken = new MyToken(symbol, totalSupply);
        deployedTokens[address(newToken)] = true;
        allTokens.push(address(newToken));
    }

    // 发行 ERC20 代币
    function mintInscription(address tokenAddr) external {
        require(deployedTokens[tokenAddr], "Token not deployed");
        MyToken token = MyToken(tokenAddr);
        token.mint(msg.sender, perMint);
    }

    // 返回已部署的所有代币地址
    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }
}