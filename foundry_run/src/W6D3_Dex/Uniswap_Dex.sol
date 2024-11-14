// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@src/UniswapV2/interfaces/IUniswapV2Router02.sol";
import "@src/UniswapV2/interfaces/IERC20.sol";

interface IDex {
    /**
     * @dev 卖出ETH，兑换成 buyToken
     *      msg.value 为出售的ETH数量
     * @param buyToken 兑换的目标代币地址
     * @param minBuyAmount 要求最低兑换到的 buyToken 数量
     */
    function sellETH(address buyToken,uint256 minBuyAmount) external payable;

    /**
     * @dev 买入ETH，用 sellToken 兑换
     * @param sellToken 出售的代币地址
     * @param sellAmount 出售的代币数量
     * @param minBuyAmount 要求最低兑换到的ETH数量
     */
    function buyETH(address sellToken,uint256 sellAmount,uint256 minBuyAmount) external;
}

contract MyDex is IDex {
    IUniswapV2Router02 public uniswapRouter;
    address public WETH;

    constructor(address _uniswapRouter) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        WETH = uniswapRouter.WETH();
    }

    /**
     * @dev 买入ETH，用 sellToken 兑换
     * @param sellToken 出售的代币地址
     * @param sellAmount 出售的代币数量
     * @param minBuyAmount 要求最低兑换到的ETH数量
     */
    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external override {
        require(sellAmount > 0, "No tokens to sell");

        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = WETH;

        IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount);
        IERC20(sellToken).approve(address(uniswapRouter), sellAmount);

        uniswapRouter.swapExactTokensForETH(
            sellAmount,
            minBuyAmount,
            path,
            msg.sender,
            block.timestamp
        );
    }
    /**
     * @dev 卖出ETH，兑换成 buyToken
     *      msg.value 为出售的ETH数量
     * @param buyToken 兑换的目标代币地址
     * @param minBuyAmount 要求最低兑换到的 buyToken 数量
     */
    function sellETH(address buyToken, uint256 minBuyAmount) external payable override {
        require(msg.value > 0, "No ETH sent");

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = buyToken;

        uniswapRouter.swapExactETHForTokens{value: msg.value}(
            minBuyAmount,
            path,
            msg.sender,
            block.timestamp
        );
    }

    // to receive ETH
    receive() external payable {}
}