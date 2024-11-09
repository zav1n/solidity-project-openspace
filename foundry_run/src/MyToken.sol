// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit { 
    constructor(string memory name_, string memory symbol_)
    ERC20(name_, symbol_)
    ERC20Permit(name_)
    {
        _mint(msg.sender, 1e10 * 1e18);
    } 
}