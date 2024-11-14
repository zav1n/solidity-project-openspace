# UniswapV2 core & router contracts

## Deployment Steps

1. Clone UniswapV2 core \* periphery contracts, update the sol version and source code.

2. Get code hash for UniswapV2Pair.sol by running.

```bash
forge script script/GetUniswapV2PairHash.sol
```

3. Deploy the WETH9.sol, UniswapV2Factory.sol, UniswapV2Router02.sol contracts.

```bash
bash ./script/deploy.sh --file ./script/DeployUniswapV2.s.sol --account <your-keystore-account>
```

## Contract Addresses

UniswapV2Router02: https://sepolia.etherscan.io/address/0xb55ab03423e61f2fb3f39c75ea60312ad942f7e1#code

UniswapV2Factory: https://sepolia.etherscan.io/address/0xda038d2c06c8437c0f9deb6ee488dd3a07ba3284#code

WETH: https://sepolia.etherscan.io/address/0xb40c466e63d949416ef54562028632802c9b215d#code
