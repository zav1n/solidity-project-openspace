// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Aave V2核心合约分析
 * @dev 本文件展示了Aave V2的核心合约结构和关键功能
 */

// ================ 地址提供者合约 ================

/**
 * @notice LendingPoolAddressesProvider是Aave协议的中央地址注册表
 * @dev 管理所有协议合约的地址，支持合约升级
 */
contract LendingPoolAddressesProvider {
    // 地址映射
    mapping(bytes32 => address) private _addresses;
    
    // 协议所有者
    address private _owner;
    
    // 市场ID
    string private _marketId;
    
    // 事件
    event MarketIdSet(string newMarketId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddressSet(bytes32 indexed id, address indexed newAddress, bool hasProxy);
    event LendingPoolUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    
    constructor(string memory marketId) {
        _owner = msg.sender;
        _marketId = marketId;
        emit MarketIdSet(marketId);
    }
    
    /**
     * @notice 设置市场ID
     */
    function setMarketId(string memory marketId) external {
        require(msg.sender == _owner, "ONLY_OWNER");
        _marketId = marketId;
        emit MarketIdSet(marketId);
    }
    
    /**
     * @notice 获取市场ID
     */
    function getMarketId() external view returns (string memory) {
        return _marketId;
    }
    
    /**
     * @notice 设置新的LendingPool实现地址
     * @dev 通过代理模式实现可升级性
     */
    function setLendingPoolImpl(address pool) external {
        require(msg.sender == _owner, "ONLY_OWNER");
        _addresses[keccak256(abi.encodePacked("LENDING_POOL"))] = pool;
        emit LendingPoolUpdated(pool);
    }
    
    /**
     * @notice 获取LendingPool地址
     */
    function getLendingPool() external view returns (address) {
        return _addresses[keccak256(abi.encodePacked("LENDING_POOL"))];
    }
    
    /**
     * @notice 设置价格预言机地址
     */
    function setPriceOracle(address priceOracle) external {
        require(msg.sender == _owner, "ONLY_OWNER");
        _addresses[keccak256(abi.encodePacked("PRICE_ORACLE"))] = priceOracle;
        emit PriceOracleUpdated(priceOracle);
    }
    
    /**
     * @notice 获取价格预言机地址
     */
    function getPriceOracle() external view returns (address) {
        return _addresses[keccak256(abi.encodePacked("PRICE_ORACLE"))];
    }
    
    // 其他地址管理函数省略...
}

// ================ 借贷池合约 ================

/**
 * @notice LendingPool是Aave协议的核心合约
 * @dev 处理所有借贷操作，包括存款、借款、还款和清算
 */
contract LendingPool {
    // 地址提供者
    ILendingPoolAddressesProvider internal _addressesProvider;
    
    // 储备金配置映射
    mapping(address => ReserveData) internal _reserves;
    
    // 用户配置映射
    mapping(address => UserConfigurationMap) internal _usersConfig;
    
    // 储备金列表
    address[] internal _reservesList;
    
    // 暂停标志
    bool internal _paused;
    
    // 事件
    event Deposit(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referral);
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
    event Borrow(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint256 borrowRateMode, uint256 borrowRate, uint16 indexed referral);
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
    event LiquidationCall(address indexed collateralAsset, address indexed debtAsset, address indexed user, uint256 debtToCover, uint256 liquidatedCollateralAmount, address liquidator, bool receiveAToken);
    
    /**
     * @notice 初始化借贷池
     */
    function initialize(ILendingPoolAddressesProvider provider) external {
        _addressesProvider = provider;
    }
    
    /**
     * @notice 存款操作
     * @dev 用户存入资产，获得对应的aToken
     */
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        require(!_paused, "PROTOCOL_PAUSED");
        
        ReserveData storage reserve = _reserves[asset];
        
        // 验证储备金状态
        require(reserve.configuration.isActive(), "RESERVE_INACTIVE");
        require(reserve.configuration.isDepositEnabled(), "DEPOSIT_DISABLED");
        
        // 转移资产到aToken合约
        IERC20(asset).transferFrom(msg.sender, reserve.aTokenAddress, amount);
        
        // 铸造aToken给用户
        IAToken(reserve.aTokenAddress).mint(onBehalfOf, amount, reserve.liquidityIndex);
        
        // 更新储备金状态
        updateInterestRates(asset, amount, 0);
        
        emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
    }
    
    /**
     * @notice 提款操作
     * @dev 用户燃烧aToken，获取原始资产
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        require(!_paused, "PROTOCOL_PAUSED");
        
        ReserveData storage reserve = _reserves[asset];
        
        // 验证储备金状态
        require(reserve.configuration.isActive(), "RESERVE_INACTIVE");
        require(reserve.configuration.isWithdrawEnabled(), "WITHDRAW_DISABLED");
        
        // 计算可提取的最大金额
        uint256 userBalance = IAToken(reserve.aTokenAddress).balanceOf(msg.sender);
        uint256 amountToWithdraw = amount == type(uint256).max ? userBalance : amount;
        
        // 验证流动性
        require(amountToWithdraw <= userBalance, "INSUFFICIENT_BALANCE");
        require(amountToWithdraw <= IERC20(asset).balanceOf(reserve.aTokenAddress), "INSUFFICIENT_LIQUIDITY");
        
        // 燃烧aToken
        IAToken(reserve.aTokenAddress).burn(msg.sender, to, amountToWithdraw, reserve.liquidityIndex);
        
        // 更新储备金状态
        updateInterestRates(asset, 0, amountToWithdraw);
        
        emit Withdraw(asset, msg.sender, to, amountToWithdraw);
        
        return amountToWithdraw;
    }
    
    /**
     * @notice 借款操作
     * @dev 用户借入资产，产生债务代币
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external {
        require(!_paused, "PROTOCOL_PAUSED");
        
        ReserveData storage reserve = _reserves[asset];
        
        // 验证储备金状态
        require(reserve.configuration.isActive(), "RESERVE_INACTIVE");
        require(reserve.configuration.isBorrowEnabled(), "BORROW_DISABLED");
        
        // 验证利率模式
        require(interestRateMode <= 2, "INVALID_INTEREST_RATE_MODE");
        
        // 验证用户健康因子
        require(getUserHealthFactor(onBehalfOf) > 1e18, "HEALTH_FACTOR_LOWER_THAN_THRESHOLD");
        
        // 铸造债务代币
        if (interestRateMode == 1) {
            // 稳定利率借款
            IStableDebtToken(reserve.stableDebtTokenAddress).mint(
                onBehalfOf,
                amount,
                reserve.currentStableBorrowRate
            );
        } else {
            // 可变利率借款
            IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
                onBehalfOf,
                amount,
                reserve.currentVariableBorrowRate
            );
        }
        
        // 转移资产给借款人
        IERC20(asset).transfer(msg.sender, amount);
        
        // 更新用户配置
        _usersConfig[onBehalfOf].setBorrowing(reserve.id, true);
        
        // 更新储备金状态
        updateInterestRates(asset, 0, amount);
        
        emit Borrow(
            asset,
            msg.sender,
            onBehalfOf,
            amount,
            interestRateMode,
            interestRateMode == 1 ? reserve.currentStableBorrowRate : reserve.currentVariableBorrowRate,
            referralCode
        );
    }
    
    /**
     * @notice 还款操作
     * @dev 用户偿还债务，燃烧债务代币
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256) {
        require(!_paused, "PROTOCOL_PAUSED");
        
        ReserveData storage reserve = _reserves[asset];
        
        // 验证储备金状态
        require(reserve.configuration.isActive(), "RESERVE_INACTIVE");
        
        // 计算债务金额
        uint256 stableDebt = IStableDebtToken(reserve.stableDebtTokenAddress).balanceOf(onBehalfOf);
        uint256 variableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).balanceOf(onBehalfOf);
        
        // 确定要偿还的债务类型
        uint256 paybackAmount;
        if (rateMode == 1) {
            require(stableDebt > 0, "NO_STABLE_DEBT");
            paybackAmount = amount == type(uint256).max ? stableDebt : amount;
            
            // 燃烧稳定债务代币
            IStableDebtToken(reserve.stableDebtTokenAddress).burn(onBehalfOf, paybackAmount);
        } else {
            require(variableDebt > 0, "NO_VARIABLE_DEBT");
            paybackAmount = amount == type(uint256).max ? variableDebt : amount;
            
            // 燃烧可变债务代币
            IVariableDebtToken(reserve.variableDebtTokenAddress).burn(onBehalfOf, paybackAmount);
        }
        
        // 转移资产到aToken合约
        IERC20(asset).transferFrom(msg.sender, reserve.aTokenAddress, paybackAmount);
        
        // 更新用户配置
        if (stableDebt + variableDebt - paybackAmount == 0) {
            _usersConfig[onBehalfOf].setBorrowing(reserve.id, false);
        }
        
        // 更新储备金状态
        updateInterestRates(asset, paybackAmount, 0);
        
        emit Repay(asset, onBehalfOf, msg.sender, paybackAmount);
        
        return paybackAmount;
    }
    
    /**
     * @notice 清算操作
     * @dev 清算不健康的头寸
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external {
        require(!_paused, "PROTOCOL_PAUSED");
        
        // 验证用户健康因子
        uint256 healthFactor = getUserHealthFactor(user);
        require(healthFactor < 1e18, "HEALTH_FACTOR_ABOVE_THRESHOLD");
        
        // 计算清算金额
        uint256 debtAssetPrice = IPriceOracle(_addressesProvider.getPriceOracle()).getAssetPrice(debtAsset);
        uint256 collateralPrice = IPriceOracle(_addressesProvider.getPriceOracle()).getAssetPrice(collateralAsset);
        
        // 计算可清算的最大债务
        uint256 maxDebtToCover = calculateMaxDebtToCover(debtAsset, user);
        debtToCover = debtToCover > maxDebtToCover ? maxDebtToCover : debtToCover;
        
        // 计算清算奖励
        uint256 bonus = calculateLiquidationBonus(collateralAsset);
        uint256 collateralAmount = (debtToCover * de