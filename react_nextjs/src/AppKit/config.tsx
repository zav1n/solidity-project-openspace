import { cookieStorage, createStorage } from "@wagmi/core";
import { WagmiAdapter } from "@reown/appkit-adapter-wagmi";
import { mainnet, sepolia } from "@reown/appkit/networks";

// Get projectId from https://cloud.reown.com
export const projectId = "5b02282c5390cbb75622cc86c78eed4d";

if (!projectId) {
  throw new Error("Project ID is not defined");
}

export const networks = [sepolia, mainnet];

//Set up the Wagmi Adapter (Config)
export const wagmiAdapter = new WagmiAdapter({
  storage: createStorage({
    storage: cookieStorage
  }),
  ssr: true,
  projectId,
  networks
});

export const config = wagmiAdapter.wagmiConfig;
