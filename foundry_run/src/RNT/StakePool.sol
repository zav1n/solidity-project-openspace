// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
  
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@src/RNT/esRNT.sol";


contract StakePool is Ownable {
  IERC20 public rntToken;
  esRNT public esrentToken;
  mapping(address => StakeInfo) public stakes;
  uint256 public rewardRate = 1 ether;

  struct StakeInfo {
    uint256 staked;
    uint256 unclaimed;
    uint256 lastUpdateTime;
  }

  constructor(IERC20 _rntToken, esRNT _esrntToken) Ownable(msg.sender) {
    rntToken = _rntToken;
    esrentToken = _esrntToken;
  }

  function stake(uint256 amount) external {
    updateReward(msg.sender);
    require(amount > 0, "Amount must be greater than zero");
    rntToken.transferFrom(msg.sender, address(this), amount);
    stakes[msg.sender].staked += amount;
  }

  function unstake(uint256 amount) external {
    updateReward(msg.sender);
    require(amount > 0, "Amount must be greater than zero");
    require(stakes[msg.sender].staked >= amount, "Insufficient stake");
    stakes[msg.sender].staked -= amount;
    rntToken.transfer(msg.sender, amount);
  }

  function claim() external {
    updateReward(msg.sender);
    uint256 reward = stakes[msg.sender].unclaimed;
    stakes[msg.sender].unclaimed = 0;
    esrentToken.transfer(msg.sender, reward);
  }

  function updateReward(address account) internal view {
    StakeInfo memory stakeInfo = stakes[account];
    if(stakeInfo.lastUpdateTime > 0) {
      uint256 holdingTime = block.timestamp - stakeInfo.lastUpdateTime;
      stakeInfo.unclaimed += (holdingTime * stakeInfo.staked * rewardRate) / 1 days;
    }
    stakeInfo.lastUpdateTime = block.timestamp;
  }

}