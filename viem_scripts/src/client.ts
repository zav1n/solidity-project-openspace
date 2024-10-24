import { createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";

const rpc = process.env.ETH_RPC_URL;

export const publicClient = createPublicClient({
  chain: mainnet,
  transport: http("https://eth-pokt.nodies.app")
});
