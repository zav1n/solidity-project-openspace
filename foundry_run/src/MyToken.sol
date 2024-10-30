// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Decert 登录的钱包来 0xeEE4739AD49c232Ef2Bb968fC2346Edbe03c8888

contract MyToken is ERC20 { 
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e10 * 1e18);
    } 
}