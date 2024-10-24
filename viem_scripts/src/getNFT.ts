import {
  createPublicClient,
  createWalletClient,
  http,
  getContract
} from "viem";
import { sepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import dotenv from "dotenv";
import { erc721Abi } from "./abi";

dotenv.config();

const account = privateKeyToAccount(`0x${process.env.PRIVATE_KEY}`);
const rpc = process.env.ETH_RPC_URL;

const walletClient = createWalletClient({
  account,
  chain: sepolia,
  transport: http(rpc)
});

const client = createPublicClient({
  chain: sepolia,
  transport: http(rpc)
});

const nftContractAddress = "0x0483b0dfc6c78062b9e999a82ffb795925381415";


// 读取持有人地址
async function getOwnerOf(tokenId: number) {
  const owner = await client.readContract({
    address: nftContractAddress,
    abi: erc721Abi,
    functionName: 'ownerOf',
    args: [tokenId],
  })
  return owner
}

// 读取元数据 URI
async function getTokenURI(tokenId: number) {
  const tokenURI = await client.readContract({
    address: nftContractAddress,
    abi: erc721Abi,
    functionName: "tokenURI",
    args: [tokenId]
  });
  return tokenURI;
}

// 更简洁的写法是使用 getContract
const contract = getContract({
  address: nftContractAddress,
  abi: erc721Abi,
  client: client
});


async function main() {
  const tokenId = 1; // 替换为你要查询的 NFT tokenId

  try {
    const owner = await getOwnerOf(tokenId);
    console.log(`NFT持有人地址: ${owner}`);

    const tokenURI = await getTokenURI(tokenId);
    console.log(`NFT元数据URI: ${tokenURI}`);

    // 如果需要进一步获取元数据，可以发起HTTP请求获取元数据
    const response = await fetch(tokenURI as string);
    const metadata = await response.json();
    console.log("NFT元数据:", metadata);
  } catch (error) {
    console.error("读取NFT信息时出错:", error);
  }


}

main().catch(console.error);
