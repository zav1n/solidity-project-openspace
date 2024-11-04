// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@src/RNT/esRNT.sol";


contract StakePool is Ownable {
  IERC20 public rntToken;
  esRNT public esrentToken;
  // 用户质押信息
  mapping(address => StakeInfo) public stakes; 
  // 每个 RNT 每天的奖励
  uint256 public constant REWARD_RATE = 1; 
  // esRNT 的锁定期
  // uint256 public constant REDEEM_TIME = 30 days; 

  struct StakeInfo {
    // 质押RNT数量
    uint256 staked;
    // 未领取的奖励
    uint256 unclaimed;
    // 最后一次更新时间
    uint256 lastUpdateTime;
  }

  constructor(IERC20 _rntToken, esRNT _esrntToken) Ownable(msg.sender) {
    rntToken = _rntToken;
    esrentToken = _esrntToken;
  }

  // 质押
  function stake(uint256 amount) external {
    updateReward(msg.sender);
    require(amount > 0, "Amount must be greater than zero");
    rntToken.transferFrom(msg.sender, address(this), amount);
    stakes[msg.sender].staked += amount;
  }

  // 解押
  function unstake(uint256 amount) external {
    updateReward(msg.sender);
    require(amount > 0, "Amount must be greater than zero");
    require(stakes[msg.sender].staked >= amount, "Insufficient stake");
    stakes[msg.sender].staked -= amount;
    rntToken.transfer(msg.sender, amount);
  }

  // 领取奖励
  function claim() external {
    updateReward(msg.sender);
    uint256 reward = stakes[msg.sender].unclaimed;
    stakes[msg.sender].unclaimed = 0;
    esrentToken.mint(msg.sender, reward);
  }

  // 兑换 esRNT 为 RNT
  function redeemEsRNT() external {
    (uint256 amount, uint256 collectionTime) = esrentToken.userLocks(msg.sender);
    require(amount > 0, "not enough token can be collection");

    esrentToken.burn(msg.sender, amount); // 销毁 esRNT
    rntToken.transfer(msg.sender, amount); // 转回 RNT

  }

  function updateReward(address account) internal {
    StakeInfo storage stakeInfo = stakes[account];
    if(stakeInfo.lastUpdateTime > 0) {
      // TODO 存在浮点数的问题, 需要加上相关计算库
      uint256 holdingTime = (block.timestamp - stakeInfo.lastUpdateTime) / 1 days; // 换成天
      stakeInfo.unclaimed += stakeInfo.staked * REWARD_RATE / 100 * holdingTime;
    }
    stakeInfo.lastUpdateTime = block.timestamp;

  }
}