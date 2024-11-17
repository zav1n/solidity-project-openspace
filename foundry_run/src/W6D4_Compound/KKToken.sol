// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KKToken is ERC20 {
  // IERC20 token;
  
  constructor(string memory _name, string memory _symbol) 
  ERC20(_name, _symbol) {}
  // Ownable(msg.sender) {
  //   _transferOwnership(msg.sender);
  // }

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }

}