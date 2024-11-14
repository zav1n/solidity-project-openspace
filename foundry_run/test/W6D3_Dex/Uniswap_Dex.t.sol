// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@src/Factory/TokenFactoryV1.sol";
import "@src/W6D3_Dex/Uniswap_Dex.sol";
import "@src/W6D3_Dex/WETH9.sol";

import "@src/UniswapV2/UniswapV2Factory.sol";
import "@src/UniswapV2/UniswapV2Router02.sol";
import "@src/UniswapV2/UniswapV2Pair.sol";
import "@src/UniswapV2/interfaces/IUniswapV2Router02.sol";
import "@src/UniswapV2/interfaces/IERC20.sol";
import "@src/UniswapV2/libraries/UniswapV2Library.sol";


contract UniswapTest is Test {
    TokenFactoryV1 tokenFactory;
    UniswapV2Factory factory;
    IUniswapV2Router02 uniswapV2Router;
    MyDex myDex;

    WETH9 WETH;
    IERC20 RNT;

    address owner = makeAddr("owner");
    function setUp() public {
        WETH = new WETH9();
        factory = new UniswapV2Factory(address(0));
        uniswapV2Router = new UniswapV2Router02(address(factory), address(WETH));

        _createToken();
        myDex = new MyDex(address(uniswapV2Router));

        _addLiquidity();
    }
    function test_buyNFT() public {
        // _addLiquidity();
        // Approve and deposit tokens
        uint256 buyETHAmount = 1 ether;
        RNT.approve(address(myDex), buyETHAmount);

        address[] memory path = new address[](2);
        path[0] = address(RNT);
        path[1] = address(WETH);

        // amountOuts = [ ? RNT, ? WETH]
        uint[] memory amountOuts = uniswapV2Router.getAmountsOut(buyETHAmount, path);

        // amounts[1] is WETH amountOut which should be greater than 0
        assertTrue(amountOuts[amountOuts.length - 1] > 0);

        // get balance before buy eth
        uint256 balanceBeforeBuyETH = address(this).balance;
        // console.log("balanceBeforeBuyETH:", balanceBeforeBuyETH);

        // with slippage
        uint256 expectMinETH = (amountOuts[amountOuts.length - 1] * 99) / 100;
        // Buy ETH
        myDex.buyETH(address(RNT), buyETHAmount, expectMinETH);

        // Check if the balance of the contract has increased
        uint256 finalBalance = address(this).balance;
        // console.log("finalBalance:", finalBalance);
        assertGe(finalBalance, balanceBeforeBuyETH + expectMinETH);
    }
    function test_sellNFT() public {
        // _addLiquidity();
        uint256 balanceRNTBeforeSellETH = RNT.balanceOf(address(this));
        console.log("balanceRNTBeforeSellETH:", balanceRNTBeforeSellETH);

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(RNT);
        // amounts[0] => ETH, amounts[1] => RNT
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(1 ether, path);
        assertTrue(amounts[amounts.length - 1] > amounts[0]);
        uint256 expectedRNTAmountOut = amounts[amounts.length - 1];
        // uint amountOut = uniswapV2Router.getAmountOut(msg.value, path);

        // sell ETH
        myDex.sellETH{value: 1 ether}(address(RNT), expectedRNTAmountOut);

        // Check if the balance of RNT has increased
        uint256 finalBalance = RNT.balanceOf(address(this));
        assertEq(finalBalance, balanceRNTBeforeSellETH + expectedRNTAmountOut);
    }
    function _createToken() private {
        tokenFactory = new TokenFactoryV1();
        tokenFactory.initialize(owner);

        tokenFactory.deployInscription("RNT", 10000 ether, 200 ether);

        RNT = IERC20(tokenFactory.deployedTokens(0));
        tokenFactory.mintInscription(address(RNT));
    }
    function _addLiquidity() private returns (uint amountA, uint amountB, uint liquidity) {
        WETH.deposit{value: 20 ether}();
        WETH.approve(address(uniswapV2Router), 20 ether);
        RNT.approve(address(uniswapV2Router), 1000 ether);

        console.log("1", address(WETH));
        console.log("2", address(RNT));
        // Add liquidity
        (amountA, amountB, liquidity) = uniswapV2Router.addLiquidity(
            address(WETH),
            address(RNT),
            20 ether,
            100 ether,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
    receive() external payable {}
}
