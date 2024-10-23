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

const rpc = process.env.ETH_RPC_URL;

const client = createPublicClient({
  chain: sepolia,
  transport: http(rpc)
});

const nftContractAddress = "0x0483b0dfc6c78062b9e999a82ffb795925381415";

// 更简洁的写法是使用 getContract
const contract = getContract({
  address: nftContractAddress,
  abi: erc721Abi,
  client: client
});

async function getInfo(tokenId: number) {
  const nftOwner = contract.read.ownerOf([tokenId]);
  console.log("owner of token no.1 nft is:\n", nftOwner);

  const nftUri = await contract.read.tokenURI([tokenId]);
  console.log("URI of token", tokenId, "nft is:\n", nftUri);
}

async function main() {
  const tokenId = 1; // 替换为你要查询的 NFT tokenId
  getInfo(tokenId);
}

main().catch(console.error);
