import { createWalletClient, createPublicClient, custom, http } from "viem";
import { mainnet } from "viem/chains";
import { defineChain } from "@reown/appkit/networks";

export const walletClient = createWalletClient({
  chain: mainnet,
  transport: custom(window.ethereum!)
});

export const publicClient = createPublicClient({
  chain: mainnet,
  transport: custom(window.ethereum!)
});


export const anvilNetwork = defineChain({
  id: 31337,
  caipNetworkId: "eip155:31337",
  chainNamespace: "eip155",
  name: "anvil",
  nativeCurrency: {
    decimals: 18,
    name: "Ether",
    symbol: "ETH"
  },
  rpcUrls: {
    default: {
      http: ["http://127.0.0.1:8545"]
      // webSocket: ["WS_RPC_URL"]
    }
  }
  // blockExplorers: {
  //   default: { name: "Explorer", url: "BLOCK_EXPLORER_URL" }
  // },
  // contracts: {
  //   // Add the contracts here
  // }
});

export const httpPublicClient = (rpcUrl: string) => createPublicClient({
  chain: mainnet,
  transport: http(rpcUrl)
});

export const [account] = await walletClient.getAddresses();
