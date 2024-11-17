// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@src/RNT/esRNT.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

import {IStaking, IToken} from "./IStakePool.sol";


/**
 * @title StakingPoolV2
 * @dev Allows staking ETH to earn KK Tokens
 */
contract StakingPoolV2 is IStaking, Ownable {
    uint256 public constant REWARD_PER_BLOCK = 10;
    // 总质押数量
    uint256 public totalStaked;
    // 上次奖励分配的区块号
    uint256 public lastRewardBlock;
    // 全局共享的累积奖励, 基于totalStaked算出来的奖励, 每当totalStaked变化时, 需要重新算奖励
    uint256 public accKKPerStake;

    IToken public kkToken;

    struct StakeInfo {
        uint256 staked; // 用户质押数量
        uint256 rewardDebt; // 用户奖励
        uint256 pendingRewards; // Pending rewards to be claimed
    }

    mapping(address => StakeInfo) public stakes;

    // Events
    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    // Constructor
    constructor(address _kkToken) Ownable(msg.sender) {
        kkToken = IToken(_kkToken);
        lastRewardBlock = block.number;
    }

    // Update reward variables
    function updateRewards() internal {
        if (totalStaked > 0) {
            uint256 blocks = block.number - lastRewardBlock;
            uint256 kkReward = blocks * REWARD_PER_BLOCK;
            accKKPerStake += kkReward * 1e18 / totalStaked;
        }
        lastRewardBlock = block.number;
    }

    // Stake ETH
    function stake() external payable override {
        require(msg.value > 0, "Must stake more than 0");
        updateRewards();

        StakeInfo storage userStake = stakes[msg.sender];

        // Calculate pending rewards and update user's reward debt
        if (userStake.staked > 0) {
            userStake.pendingRewards += userStake.staked * accKKPerStake / 1e18 - userStake.rewardDebt;
        }

        userStake.staked += msg.value;
        userStake.rewardDebt = userStake.staked * accKKPerStake / 1e18;
        totalStaked += msg.value;

        emit Stake(msg.sender, msg.value);
    }

    // Unstake ETH
    function unstake(uint256 amount) external override {
        StakeInfo storage userStake = stakes[msg.sender];
        require(amount > 0, "Must unstake more than 0");
        require(userStake.staked >= amount, "Insufficient stake");

        updateRewards();

        // 计算待领取的奖励
        userStake.pendingRewards += userStake.staked * accKKPerStake / 1e18 - userStake.rewardDebt;

        userStake.staked -= amount;
        userStake.rewardDebt = userStake.staked * accKKPerStake / 1e18;
        totalStaked -= amount;

        payable(msg.sender).transfer(amount);

        emit Unstake(msg.sender, amount);
    }

    // Claim KK Token rewards
    function claim() external override {
        updateRewards();

        StakeInfo storage userStake = stakes[msg.sender];
        uint256 rewards = userStake.pendingRewards + userStake.staked * accKKPerStake / 1e18 - userStake.rewardDebt;

        require(rewards > 0, "No rewards to claim");

        userStake.pendingRewards = 0;
        userStake.rewardDebt = userStake.staked * accKKPerStake / 1e18;

        kkToken.mint(msg.sender, rewards);

        emit Claim(msg.sender, rewards);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return stakes[account].staked;
    }

    // 查询获取待领取的 KK Token 收益
    function earned(address account) external override view returns (uint256) {
        require(account != address(0), "Invalid account");
        StakeInfo storage userStake = stakes[account];
        uint256 currentAccKKPerStake = accKKPerStake;

        if (block.number > lastRewardBlock && totalStaked > 0) {
            uint256 blocks = block.number - lastRewardBlock;
            uint256 kkReward = blocks * REWARD_PER_BLOCK;
            currentAccKKPerStake += kkReward * 1e18 / totalStaked;
        }

        return userStake.pendingRewards + userStake.staked * currentAccKKPerStake / 1e18 - userStake.rewardDebt;
    }
}