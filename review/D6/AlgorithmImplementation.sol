// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DeFi算法实现示例
 * @dev 展示DeFi协议中常见算法的Solidity实现
 */

// ================ 1. 恒定乘积自动做市商(CPMM) ================

/**
 * @notice 实现Uniswap风格的恒定乘积算法
 */
contract ConstantProductAMM {
    // 储备金
    uint256 private _reserve0;
    uint256 private _reserve1;
    
    // 总流动性代币供应量
    uint256 private _totalSupply;
    // 流动性代币余额映射
    mapping(address => uint256) private _balances;
    
    // 手续费率（0.3%）
    uint256 private constant FEE_NUMERATOR = 3;
    uint256 private constant FEE_DENOMINATOR = 1000;
    
    // 事件
    event Mint(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut, bool isToken0In);
    
    /**
     * @notice 添加流动性
     * @dev 首次添加流动性时，铸造的LP代币数量等于sqrt(amount0 * amount1)
     */
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 liquidity) {
        // 计算流动性代币数量
        if (_totalSupply == 0) {
            // 首次添加流动性
            liquidity = Math.sqrt(amount0 * amount1);
            
            // 更新储备金
            _reserve0 = amount0;
            _reserve1 = amount1;
        } else {
            // 非首次添加流动性，按比例计算
            uint256 liquidity0 = (amount0 * _totalSupply) / _reserve0;
            uint256 liquidity1 = (amount1 * _totalSupply) / _reserve1;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            
            // 更新储备金
            _reserve0 += amount0;
            _reserve1 += amount1;
        }
        
        // 铸造流动性代币
        _mint(msg.sender, liquidity);
        _totalSupply += liquidity;
        
        emit Mint(msg.sender, amount0, amount1, liquidity);
        return liquidity;
    }
    
    /**
     * @notice 移除流动性
     * @dev 按比例返还储备金
     */
    function removeLiquidity(uint256 liquidity) external returns (uint256 amount0, uint256 amount1) {
        require(liquidity > 0, "Insufficient liquidity");
        require(_balances[msg.sender] >= liquidity, "Insufficient balance");
        
        // 计算应返还的代币数量
        amount0 = (liquidity * _reserve0) / _totalSupply;
        amount1 = (liquidity * _reserve1) / _totalSupply;
        
        // 销毁流动性代币
        _burn(msg.sender, liquidity);
        _totalSupply -= liquidity;
        
        // 更新储备金
        _reserve0 -= amount0;
        _reserve1 -= amount1;
        
        emit Burn(msg.sender, amount0, amount1, liquidity);
        return (amount0, amount1);
    }
    
    /**
     * @notice 交换代币
     * @dev 实现恒定乘积公式 x * y = k
     */
    function swap(uint256 amountIn, bool isToken0In) external returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        
        // 确定输入和输出储备金
        uint256 reserveIn = isToken0In ? _reserve0 : _reserve1;
        uint256 reserveOut = isToken0In ? _reserve1 : _reserve0;
        
        // 计算手续费
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR) / FEE_DENOMINATOR;
        
        // 计算输出金额，保持恒定乘积
        // (reserveIn + amountInWithFee) * (reserveOut - amountOut) = reserveIn * reserveOut
        amountOut = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);
        
        require(amountOut > 0, "Insufficient output amount");
        require(amountOut < reserveOut, "Insufficient liquidity");
        
        // 更新储备金
        if (isToken0In) {
            _reserve0 += amountIn;
            _reserve1 -= amountOut;
        } else {
            _reserve1 += amountIn;
            _reserve0 -= amountOut;
        }
        
        emit Swap(msg.sender, amountIn, amountOut, isToken0In);
        return amountOut;
    }
    
    /**
     * @notice 获取当前储备金
     */
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1) {
        return (_reserve0, _reserve1);
    }
    
    /**
     * @notice 计算交换输出金额
     * @dev 用于前端预览
     */
    function getAmountOut(uint256 amountIn, bool isToken0In) external view returns (uint256) {
        require(amountIn > 0, "Insufficient input amount");
        
        uint256 reserveIn = isToken0In ? _reserve0 : _reserve1;
        uint256 reserveOut = isToken0In ? _reserve1 : _reserve0;
        
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR) / FEE_DENOMINATOR;
        return (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);
    }
    
    // 内部函数
    function _mint(address to, uint256 amount) internal {
        _balances[to] += amount;
    }
    
    function _burn(address from, uint256 amount) internal {
        _balances[from] -= amount;
    }
}

// ================ 2. 恒定和自动做市商(CSAMM) ================

/**
 * @notice 实现Curve风格的恒定和算法
 * @dev 适用于稳定币交易对
 */
contract ConstantSumAMM {
    // 储备金
    uint256 private _reserve0;
    uint256 private _reserve1;
    
    // 放大因子，用于提高精度
    uint256 private constant PRECISION = 1e18;
    
    // 振幅系数，控制价格曲线
    uint256 private _amplificationCoefficient = 85;
    
    // 手续费率（0.04%）
    uint256 private constant FEE_NUMERATOR = 4;
    uint256 private constant FEE_DENOMINATOR = 10000;
    
    /**
     * @notice 计算不变量D
     * @dev 使用牛顿迭代法求解方程：An^n sum(x_i) + D = ADn^n + D^(n+1)/(n^n prod(x_i))
     */
    function _calculateD(uint256 reserve0, uint256 reserve1) internal view returns (uint256) {
        uint256 sum = reserve0 + reserve1;
        if (sum == 0) return 0;
        
        uint256 n = 2; // 两种代币
        uint256 a = _amplificationCoefficient;
        uint256 ann = a * n * n;
        
        // 初始猜测值
        uint256 d = sum;
        uint256 d_prev;
        
        // 牛顿迭代
        for (uint256 i = 0; i < 255; i++) {
            uint256 d_prod = d;
            d_prod = (d_prod * d) / (reserve0 * n);
            d_prod = (d_prod * d) / (reserve1 * n);
            d_prev = d;
            d = (ann * sum + d_prod * n) * d / ((ann - 1) * d + (n + 1) * d_prod);
            
            // 收敛检查
            if (d > d_prev) {
                if (d - d_prev <= 1) break;
            } else {
                if (d_prev - d <= 1) break;
            }
        }
        
        return d;
    }
    
    /**
     * @notice 计算交换输出金额
     * @dev 基于恒定和公式
     */
    function getAmountOut(uint256 amountIn, bool isToken0In) external view returns (uint256) {
        require(amountIn > 0, "Insufficient input amount");
        
        uint256 reserveIn = isToken0In ? _reserve0 : _reserve1;
        uint256 reserveOut = isToken0In ? _reserve1 : _reserve0;
        
        // 计算手续费
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR) / FEE_DENOMINATOR;
        
        // 计算不变量D
        uint256 d = _calculateD(_reserve0, _reserve1);
        
        // 计算新的储备金
        uint256 newReserveIn = reserveIn + amountInWithFee;
        uint256 newReserveOut;
        
        if (isToken0In) {
            newReserveOut = _getY(newReserveIn, d);
        } else {
            newReserveOut = _getY(newReserveIn, d);
        }
        
        // 计算输出金额
        require(newReserveOut < reserveOut, "Invalid result");
        return reserveOut - newReserveOut;
    }
    
    /**
     * @notice 计算给定x和D时的y值
     * @dev 求解方程：y = (D^(n+1)/(An^n * x) - D) / (1 + 1/(An^n))
     */
    function _getY(uint256 x, uint256 d) internal view returns (uint256) {
        uint256 n = 2; // 两种代币
        uint256 a = _amplificationCoefficient;
        uint256 ann = a * n * n;
        
        uint256 c = d * d / (x * n);
        c = c * d / (ann * n);
        
        uint256 b = x + d / ann;
        uint256 y_prev;
        uint256 y = d;
        
        // 牛顿迭代
        for (uint256 i = 0; i < 255; i++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - d);
            
            // 收敛检查
            if (y > y_prev) {
                if (y - y_prev <= 1) break;
            } else {
                if (y_prev - y <= 1) break;
            }
        }
        
        return y;
    }
    
    // 其他函数省略...
}

// ================ 3. 借贷利率模型 ================

/**
 * @notice 实现Aave风格的动态利率模型
 */
contract DynamicRateModel {
    // 利用率精度
    uint256 private constant UTILIZATION_RATE_PRECISION = 1e18;
    
    // 利率参数
    uint256 private _baseRate = 1e16; // 1% 基础利率
    uint256 private _slope1 = 4e16;   // 4% 第一斜率
    uint256 private _slope2 = 60e16;  // 60% 第二斜率
    uint256 private _optimalUtilizationRate = 8e17; // 80% 最优利用率
    
    /**
     * @notice 计算借款利率
     * @dev 基于当前利用率
     */
    function calculateBorrowRate(uint256 totalBorrows, uint256 totalLiquidity) external view returns (uint256) {
        if (totalLiquidity == 0) return _baseRate;
        
        // 计算利用率 = 总借款 / 总流动性
        uint256 utilizationRate = (totalBorrows * UTILIZATION_RATE_PRECISION) / totalLiquidity;
        
        if (utilizationRate <= _optimalUtilizationRate) {
            // 利用率低于最优值，使用第一斜率
            return _baseRate + (utilizationRate * _slope1) / UTILIZATION_RATE_PRECISION;
        } else {
            // 利用率高于最优值，使用第二斜率
            uint256 normalRate = _baseRate + (_optimalUtilizationRate * _slope1) / UTILIZATION_RATE_PRECISION;
            uint256 excessUtilization = utilizationRate - _optimalUtilizationRate;
            return normalRate + (excessUtilization * _slope2) / UTILIZATION_RATE_PRECISION;
        }
    }
    
    /**
     * @notice 计算存款利率
     * @dev 基于借款利率和利用率
     */
    function calculateDepositRate(uint256 totalBorrows, uint256 totalLiquidity) external view returns (uint256) {
        if (totalLiquidity == 0) return 0;
        
        // 计算利用率
        uint256 utilizationRate = (totalBorrows * UTILIZATION_RATE_PRECISION) / totalLiquidity;