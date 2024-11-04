// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract esRNT is ERC20, Ownable {
  struct lockInfo{
    uint256 amount;
    uint256 collectionTime; // 领取时间
  }
  
  mapping(address => lockInfo) public userLocks;

  IERC20 rntToken;
  
  event Minted(address, uint256, lockInfo);
  constructor(IERC20 _rntToken) ERC20("esRNT", "esRNT") Ownable(msg.sender) {
    rntToken = _rntToken;
    _transferOwnership(msg.sender);
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
    lockInfo storage userLock = userLocks[to];
    userLock.amount += amount;
    userLock.collectionTime = block.timestamp;
    emit Minted(to, amount, userLock);
  }

  function burn(address user, uint256 amount) public {
    lockInfo storage userinfo = userLocks[user];
    uint256 unlockAmount = (block.timestamp - userinfo.collectionTime) * amount / 30 days ;
    userinfo.collectionTime = block.timestamp;  // 更新领取时间
    _burn(user, amount);
  }

  function getUserlocks(address user) public view returns(lockInfo memory) {
    return userLocks[user];
  }
}