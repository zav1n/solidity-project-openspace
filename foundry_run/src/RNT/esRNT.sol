// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract esRNT is ERC20, Ownable {
  struct lockInfo{
    address user;
    uint256 amount;
    uint256 lockTime;
  }
  lockInfo[] public locks;

  IERC20 rntToken;
  
  event Minted(address, uint256, uint256);
  constructor(IERC20 _rntToken) ERC20("esRNT", "esRNT") Ownable(msg.sender) {
    rntToken = _rntToken;
    _transferOwnership(msg.sender);
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
    locks.push(lockInfo({
      user: to,
      amount: amount,
      lockTime: block.timestamp
    }));
    uint256 lockId = locks.length - 1;
    emit Minted(to, amount, lockId);
  }

  function burn(uint256 lockId) public {
    require(lockId < locks.length - 1, "non-existent lockId");
    lockInfo memory lock = locks[lockId];
    require(lock.user == msg.sender, "only lock owner can burn");
    uint256 unlockAmount = (lock.amount*(block.timestamp - lock.lockTime))/ 30 days;
    uint256 burnAmount = lock.amount - unlockAmount;
    
    _burn(msg.sender, lock.amount); // 池子需要减去一开始mint的总数
    rntToken.transfer(address(0), burnAmount); // 销毁esRNT

    rntToken.transfer(msg.sender, unlockAmount); // 转回RNT

  }

  function getUserlocks(address user) public view returns(lockInfo[] memory) {
    // ATTENTION: 不建议在这里遍历找用户的锁仓信息
    uint256 count;
    for (uint256 i = 0; i < locks.length; i++) {
      if(locks[i].user == user) {
        count++;
      }
    }
    lockInfo[] memory userLocks = new lockInfo[](count);
    uint256 index = 0;
    for (uint256 i = 0; i < locks.length; i++) {
      if(locks[i].user == user) {
        userLocks[index] = locks[i];
        index++;
      }
    }
    return userLocks;
  }

  function getBylockId(uint256 locks_id)  public view returns(lockInfo memory) {
    return locks[locks_id];
  }
}