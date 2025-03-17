// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Compound核心合约分析
 * @dev 本文件展示了Compound的核心合约结构和关键功能
 */

// ================ cToken合约 ================

/**
 * @notice cToken是Compound协议的核心，代表用户在协议中的存款
 * @dev 实现了ERC20标准，并通过兑换率机制自动累积利息
 */
contract CToken {
    // ERC20相关变量
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Compound特有变量
    address public underlying;           // 基础资产地址（如DAI、USDC等，cETH没有此变量）
    address public comptroller;          // 风控合约地址
    address public interestRateModel;    // 利率模型合约地址
    
    // 兑换率相关变量
    uint256 public exchangeRateStored;   // 最近更新的兑换率
    uint256 public accrualBlockNumber;   // 最近更新利息的区块号
    
    // 市场状态变量
    uint256 public totalBorrows;         // 总借款金额
    uint256 public totalReserves;        // 总储备金额
    uint256 public reserveFactor;        // 储备因子（0-1之间）
    
    // 事件
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows);
    event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows);
    event LiquidateBorrow(address liquidator, address borrower, uint256 repayAmount, address cTokenCollateral, uint256 seizeTokens);
    
    /**
     * @notice 计算当前兑换率
     * @dev 兑换率 = (现金 + 总借款 - 总储备) / 总供应量
     * 兑换率随时间增加，反映了累积的利息
     */
    function exchangeRateCurrent() public returns (uint256) {
        // 更新利息
        accrueInterest();
        // 返回当前兑换率
        return exchangeRateStored;
    }
    
    /**
     * @notice 更新累积利息
     * @dev 根据时间流逝和利率模型计算新增利息
     */
    function accrueInterest() public returns (uint256) {
        // 获取当前区块
        uint256 currentBlock = block.number;
        // 计算经过的区块数
        uint256 blockDelta = currentBlock - accrualBlockNumber;
        
        if (blockDelta == 0) {
            return 0; // 无需更新
        }
        
        // 从利率模型获取当前借款利率
        uint256 borrowRate = InterestRateModel(interestRateModel).getBorrowRate();
        
        // 计算利息: 利率 * 时间 * 总借款
        uint256 interestAccumulated = borrowRate * blockDelta * totalBorrows / 1e18;
        
        // 更新总借款
        totalBorrows += interestAccumulated;
        
        // 计算储备金
        uint256 reservesAdded = interestAccumulated * reserveFactor / 1e18;
        totalReserves += reservesAdded;
        
        // 更新兑换率
        // 假设getCash()返回合约中的现金余额
        uint256 cash = getCash();
        uint256 newExchangeRate = (cash + totalBorrows - totalReserves) * 1e18 / totalSupply;
        exchangeRateStored = newExchangeRate;
        
        // 更新累积区块号
        accrualBlockNumber = currentBlock;
        
        return 0; // 成功
    }
    
    /**
     * @notice 存款功能
     * @dev 用户存入基础资产，获得对应的cToken
     */
    function mint(uint256 mintAmount) external returns (uint256) {
        // 更新利息
        accrueInterest();
        
        // 检查用户是否被允许参与市场
        Comptroller(comptroller).mintAllowed(address(this), msg.sender, mintAmount);
        
        // 计算铸造的cToken数量: 存款金额 / 兑换率
        uint256 mintTokens = mintAmount * 1e18 / exchangeRateStored;
        
        // 转入基础资产
        // 实际实现中会使用transferFrom
        
        // 铸造cToken
        totalSupply += mintTokens;
        balanceOf[msg.sender] += mintTokens;
        
        emit Mint(msg.sender, mintAmount, mintTokens);
        return 0; // 成功
    }
    
    /**
     * @notice 借款功能
     * @dev 用户借出基础资产，增加借款余额
     */
    function borrow(uint256 borrowAmount) external returns (uint256) {
        // 更新利息
        accrueInterest();
        
        // 检查用户是否被允许借款
        Comptroller(comptroller).borrowAllowed(address(this), msg.sender, borrowAmount);
        
        // 更新总借款
        totalBorrows += borrowAmount;
        
        // 更新用户借款余额
        // 实际实现中会有一个借款余额映射
        
        // 转出基础资产给借款人
        // 实际实现中会使用transfer
        
        emit Borrow(msg.sender, borrowAmount, 0); // 0代表用户更新后的借款余额
        return 0; // 成功
    }
    
    /**
     * @notice 获取合约中的现金余额
     * @dev 对于大多数cToken，这是基础ERC20的余额
     */
    function getCash() internal view returns (uint256) {
        // 实际实现中会返回基础资产的余额
        return 0;
    }
}

// ================ 风控合约 ================

/**
 * @notice Comptroller是Compound协议的风险控制中心
 * @dev 管理市场准入、抵押品因子和清算逻辑
 */
contract Comptroller {
    // 市场状态
    struct Market {
        bool isListed;           // 市场是否已上线
        uint256 collateralFactor; // 抵押品因子 (0-1e18)
    }
    
    // 市场映射: cToken地址 => 市场信息
    mapping(address => Market) public markets;
    
    // 用户进入的市场
    mapping(address => address[]) public accountAssets; // 用户地址 => 用户参与的cToken列表
    
    // 价格预言机
    address public oracle;
    
    // 关闭因子 (用于清算)
    uint256 public closeFactorMantissa;
    
    // 清算激励
    uint256 public liquidationIncentiveMantissa;
    
    // COMP代币地址
    address public compToken;
    
    /**
     * @notice 检查用户是否可以存款
     * @dev 验证市场状态和用户状态
     */
    function mintAllowed(address cToken, address minter, uint256 mintAmount) external returns (uint256) {
        // 检查市场是否已上线
        Market storage market = markets[cToken];
        require(market.isListed, "market not listed");
        
        // 如果用户尚未进入该市场，将其添加到用户的资产列表中
        _addToMarket(cToken, minter);
        
        return 0; // 成功
    }
    
    /**
     * @notice 检查用户是否可以借款
     * @dev 验证市场状态、用户流动性和借款限额
     */
    function borrowAllowed(address cToken, address borrower, uint256 borrowAmount) external returns (uint256) {
        // 检查市场是否已上线
        Market storage market = markets[cToken];
        require(market.isListed, "market not listed");
        
        // 确保用户已进入该市场
        require(_checkMembership(borrower, cToken), "not entered market");
        
        // 检查用户是否有足够的抵押品
        require(getAccountLiquidity(borrower) >= borrowAmount, "insufficient liquidity");
        
        return 0; // 成功
    }
    
    /**
     * @notice 计算用户的账户流动性
     * @dev 流动性 = 抵押品价值 * 抵押品因子 - 借款价值
     */
    function getAccountLiquidity(address account) public view returns (uint256) {
        // 实际实现中会遍历用户的所有资产和负债
        // 计算总抵押品价值和总借款价值
        return 0; // 简化实现
    }
    
    /**
     * @notice 将用户添加到市场
     */
    function _addToMarket(address cToken, address user) internal {
        if (!_checkMembership(user, cToken)) {
            accountAssets[user].push(cToken);
        }
    }
    
    /**
     * @notice 检查用户是否已进入市场
     */
    function _checkMembership(address account, address cToken) internal view returns (bool) {
        address[] storage userAssets = accountAssets[account];
        for (uint i = 0; i < userAssets.length; i++) {
            if (userAssets[i] == cToken) {
                return true;
            }
        }
        return false;
    }
}

// ================ 利率模型合约 ================

/**
 * @notice InterestRateModel定义了借款利率的计算方式
 * @dev 基于资金利用率的动态利率模型
 */
contract InterestRateModel {
    // 基础利率
    uint256 public baseRatePerBlock;
    
    // 利用率乘数
    uint256 public multiplierPerBlock;
    
    // 跳跃利用率
    uint256 public jumpMultiplierPerBlock;
    uint256 public kink;
    
    /**
     * @notice 计算当前借款利率
     * @dev 基于资金利用率的分段线性模型
     */
    function getBorrowRate() external view returns (uint256) {
        // 获取资金利用率: 总借款 / (总现金 + 总借款)
        uint256 utilizationRate = getUtilizationRate();
        
        if (utilizationRate <= kink) {
            // 正常利率: 基础利率 + 利用率 * 乘数
            return baseRatePerBlock + utilizationRate * multiplierPerBlock / 1e18;
        } else {
            // 跳跃利率: 基础利率 + kink * 乘数 + (利用率 - kink) * 跳跃乘数
            uint256 normalRate = baseRatePerBlock + kink * multiplierPerBlock / 1e18;
            uint256 excessUtil = utilizationRate - kink;
            return normalRate + excessUtil * jumpMultiplierPerBlock / 1e18;
        }
    }
    
    /**
     * @notice 计算资金利用率
     */
    function getUtilizationRate() internal pure returns (uint256) {
        // 实际实现中会使用总借款和总现金计算
        return 0; // 简化实现
    }
}