// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RNT is ERC20, ERC20Permit, Ownable {
  constructor() ERC20("RNT", "RNT") ERC20Permit("RNT") Ownable(msg.sender){
    // decimals from ERC20, return 18
    _mint(msg.sender, 1000000000 * 10 ** decimals());
  }
}