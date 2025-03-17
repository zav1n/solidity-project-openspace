// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Uniswap V2核心合约分析
 * @dev 本文件展示了Uniswap V2的核心合约结构和关键功能
 */

// ================ 工厂合约 ================

/**
 * @notice UniswapV2Factory负责创建和管理所有交易对
 */
contract UniswapV2Factory {
    // 交易对创建事件
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    
    // 所有交易对的映射关系
    mapping(address => mapping(address => address)) public getPair;
    // 所有交易对的数组
    address[] public allPairs;
    
    // 协议费用接收地址
    address public feeTo;
    // 费用设置权限地址
    address public feeToSetter;
    
    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }
    
    /**
     * @notice 创建新的交易对
     * @dev 确保交易对不存在，并按照地址大小排序token0和token1
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS');
        
        // 创建新的交易对合约
        // 实际实现中使用CREATE2操作码以确保地址确定性
        pair = address(new UniswapV2Pair());
        
        // 初始化交易对
        UniswapV2Pair(pair).initialize(token0, token1);
        
        // 更新映射和数组
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // 反向映射也要设置
        allPairs.push(pair);
        
        emit PairCreated(token0, token1, pair, allPairs.length);

        return pair;
    }
    
    /**
     * @notice 设置协议费用接收地址
     */
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }
    
    /**
     * @notice 设置费用设置权限地址
     */
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

// ================ 交易对合约 ================

/**
 * @notice UniswapV2Pair实现AMM核心逻辑
 */
contract UniswapV2Pair {
    // ERC20相关变量
    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
    uint8 public constant decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    // 交易对状态变量
    uint112 private reserve0;           // token0的储备量
    uint112 private reserve1;           // token1的储备量
    uint32  private blockTimestampLast; // 最后更新时间戳
    
    // 价格累积变量，用于TWAP
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    
    // 最小流动性，永久锁定
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    
    // 交易对中的两个代币
    address public token0;
    address public token1;
    
    // 事件
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    
    /**
     * @notice 初始化交易对
     */
    function initialize(address _token0, address _token1) external {
        require(token0 == address(0) && token1 == address(0), 'UniswapV2: ALREADY_INITIALIZED');
        token0 = _token0;
        token1 = _token1;
    }
    
    /**
     * @notice 更新储备量
     * @dev 同时更新价格累积，用于TWAP
     */
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // 更新价格累积，用于TWAP
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }
    
    /**
     * @notice 添加流动性
     * @return liquidity 铸造的LP代币数量
     */
    function mint(address to) external returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;
        
        // 计算流动性代币数量
        if (totalSupply == 0) {
            // 首次添加流动性
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // 永久锁定最小流动性
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // 非首次添加流动性，按比例计算
            liquidity = Math.min(
                amount0 * totalSupply / _reserve0,
                amount1 * totalSupply / _reserve1
            );
        }
        
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);
        
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }
    
    /**
     * @notice 移除流动性
     * @return amount0 返回的token0数量
     * @return amount1 返回的token1数量
     */
    function burn(address to) external returns (uint amount0, uint amount1) {
        uint liquidity = balanceOf[address(this)];
        
        // 计算应返还的代币数量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint _totalSupply = totalSupply;
        amount0 = liquidity * _reserve0 / _totalSupply;
        amount1 = liquidity * _reserve1 / _totalSupply;
        
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        
        // 销毁LP代币
        _burn(address(this), liquidity);
        
        // 转移代币给接收者
        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);
        
        // 更新储备量
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        
        emit Burn(msg.sender, amount0, amount1, to);

        returns (amount0, amount1);
    }
    
    /**
     * @notice 交换代币
     * @dev 核心交易功能，实现恒定乘积公式 x * y = k
     */
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');
        
        // 转移代币给接收者
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        
        // 如果有回调数据，执行回调（用于闪电贷）
        if (data.length > 0) {
            IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        }
        
        // 计算交易后的余额
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        
        // 计算实际输入金额
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        
        // 验证交易是否符合恒定乘积公式 (考虑手续费0.3%)
        uint balance0Adjusted = balance0 * 1000 - amount0In * 3;
        uint balance1Adjusted = balance1 * 1000 - amount1In * 3;
        require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * uint(_reserve1) * 1000**2, 'UniswapV2: K');
        
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
    
    /**
     * @notice 获取当前储备量
     */
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
    
    // 其他辅助函数省略...
}

// ================ 路由合约 ================

/**
 * @notice UniswapV2Router02是用户交互的主要接口
 */
contract UniswapV2Router02 {
    address public immutable factory;
    address public immutable WETH;
    
    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }
    
    /**
     * @notice 添加流动性
     * @dev 用户友好的接口，处理滑点和截止时间
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        
        // 获取或创建交易对
        address pair = UniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = UniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        
        // 计算最优添加比例
        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        
        // 转移代币到交易对合约
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        
        // 添加流动性并返回LP代币
        liquidity = UniswapV2Pair(pair).mint(to);
    }
    
    /**
     * @notice 添加ETH和代币的流动性
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        
        // 将ETH视为WETH处理
        (amountToken, amountETH, liquidity) = addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
        
        // 如果有ETH剩余，退还给用户
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }
    
    /**
     * @notice 移除流动性
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public returns (uint amountA, uint amountB) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        
        // 获取交易对地址
        address pair = UniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), 'UniswapV2Router: PAIR_NOT_FOUND');
        
        // 将LP代币转移到交易对合约
        UniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        
        // 销毁LP代币并获取代币
        (amountA, amountB) = UniswapV2Pair(pair).burn(to);
        
        // 确保返回的代币数量满足最小要求
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    
    /**
     * @notice 移除ETH和代币的流动性
     */
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public returns (uint amountToken, uint amountETH) {
        // 调用removeLiquidity函数，将WETH视为ETH处理
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        
        // 将WETH转换为ETH并发送给接收者
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    
    /**
     * @notice 计算等价交换数量
     * @dev 根据恒定乘积公式计算
     */
    function quote(uint amountA, uint reserveA, uint reserveB) public pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Router: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Router: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }
    
    /**
     * @notice 获取交易对的储备量
     */
    function getReserves(address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        // 按地址大小排序token0和token1
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (uint112 reserve0, uint112 reserve1,) = UniswapV2Pair(UniswapV2Factory(factory).getPair(token0, token1)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        returns (reserveA, reserveB);
    }
    
    /**
     * @notice 计算交易路径上的输出金额
     */
    function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Router: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        
        for (uint i = 0; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
    
    /**
     * @notice 计算交易路径上的输入金额
     */
    function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Router: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
    
    /**
     * @notice 计算单次交换的输出金额
     * @dev 考虑0.3%的手续费
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Router: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Router: INSUFFICIENT_LIQUIDITY');
        
        uint amountInWithFee = amountIn * 997; // 0.3%手续费
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
    
    /**
     * @notice 计算单次交换的输入金额
     * @dev 考虑0.3%的手续费
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Router: INSUFFICIENT_LIQUIDITY');
        
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1; // 向上取整
    }
    
    /**
     * @notice 使用确切的输入金额交换代币
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        
        // 计算交易路径上的输出金额
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        
        // 将第一个代币转移到第一个交易对
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Factory(factory).getPair(path[0], path[1]), amounts[0]);
        
        // 执行交易
        _swap(amounts, path, to);
    }
    
    /**
     * @notice 使用确切的输出金额交换代币
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        
        // 计算交易路径上的输入金额
        amounts = getAmountsIn(amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        
        // 将第一个代币转移到第一个交易对
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Factory(factory).getPair(path[0], path[1]), amounts[0]);
        
        // 执行交易
        _swap(amounts, path, to);
    }
    
    /**
     * @notice 使用确切的ETH输入金额交换代币
     */
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        
        // 计算交易路径上的输出金额
        amounts = getAmountsOut(msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        
        // 将ETH转换为WETH并发送到第一个交易对
        IWETH(WETH).deposit{value: amounts[0]}();
        IWETH(WETH).transfer(UniswapV2Factory(factory).getPair(path[0], path[1]), amounts[0]);
        
        // 执行交易
        _swap(amounts, path, to);
    }
    
    /**
     * @notice 使用确切的代币输入金额交换ETH
     */
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        
        // 计算交易路径上的输出金额
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        
        // 将第一个代币转移到第一个交易对
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Factory(factory).getPair(path[0], path[1]), amounts[0]);
        
        // 执行交易，将WETH发送到路由合约
        _swap(amounts, path, address(this));
        
        // 将WETH转换为ETH并发送给接收者
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    
    /**
     * @notice 内部交换函数
     * @dev 执行多跳交易
     */
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = input < output ? (input, output) : (output, input);
            uint amountOut = amounts[i + 1];
            
            // 确定输出金额
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            
            // 确定接收者（最后一跳发送给用户，中间跳发送给下一个交易对）
            address to = i < path.length - 2 ? UniswapV2Factory(factory).getPair(output, path[i + 2]) : _to;
            
            // 执行交换
            UniswapV2Pair(UniswapV2Factory(factory).getPair(input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// ================ 辅助合约和接口 ================

/**
 * @notice 数学库
 */
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
    
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/**
 * @notice 定点数库
 */
library UQ112x112 {
    uint224 constant Q112 = 2**112;
    
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }
    
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

/**
 * @notice 转账辅助库
 */
library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value: value}('');
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

/**
 * @notice ERC20接口
 */
interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

/**
 * @notice WETH接口
 */
interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
    function transfer(address to, uint value) external returns (bool);
}

/**
 * @notice 回调接口
 */
interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}