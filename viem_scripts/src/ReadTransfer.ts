import { createPublicClient, http, formatUnits } from "viem";
import { mainnet } from "viem/chains";
import { parseAbiItem } from "viem";
import { watchBlockNumber } from "viem/_types/actions/public/watchBlockNumber";
import usdtAbi from "./usdtAbi";

const rpc = process.env.ETH_RPC_URL;

export const publicClient = createPublicClient({
  chain: mainnet,
  transport: http("https://rpc.flashbots.net")
});


async function getTransfer() {
  const filter = await publicClient.createEventFilter({
    address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    event: parseAbiItem(
      "event Transfer(address indexed from, address indexed to, uint256 value)"
    ),
    fromBlock: BigInt(await publicClient.getBlockNumber()) - BigInt(100),
    toBlock: "latest",
    // args: {
    //   from: "0x099bc3af8a85015d1A39d80c42d10c023F5162F0",
    //   to: "0xA4D65Fd5017bB20904603f0a174BBBD04F81757c"
    // }
  });


  // console.log("filter", filter);

  const logs = await publicClient.getFilterLogs({ filter });

  for (const log of logs) {
    const { from, to, value } = log.args || {};
    if (from && to && value) {
      const formattedValue = Number(formatUnits(value, 6)).toFixed(5);
      console.log(
        `从 ${from} 转账给 ${to} ${formattedValue} USDC, 交易ID：${log.transactionHash}`
      );
    } else {
      console.log("日志解析错误：", log);
    }
  }

}

// 监听区块高度
const watchBlock = async () => {
  const unwatch = publicClient.watchBlockNumber({
    onBlockNumber: async (blockNumber) => {
      const { hash } = await publicClient.getTransaction({
        blockNumber: BigInt(blockNumber),
        index: 0 // 这里假设 index 为 0，你可以根据实际情况调整
      });
      console.warn("transaction", `${blockNumber} ${hash}`);
    }
  });
  console.warn("unwatch", unwatch);
}

// 监听交易
const getLatestTransfer = async () => {
  const unwatch = publicClient.watchContractEvent({
    address: "0xdac17f958d2ee523a2206206994597c13d831ec7",
    abi: usdtAbi,
    eventName: "Transfer",
    onLogs: (logs) => {
      logs.forEach((log) => {
        const { blockNumber, blockHash } = log;
        const { from, to, value } = (log as any).args || {}; ;
        console.log(
          `在 ${blockNumber} 区块 ${blockHash}，${from} 转帐 ${value} ${to} `
        );
      });
    }
  });
}

// getTransfer().catch(console.error);


// watchBlock();

getLatestTransfer();