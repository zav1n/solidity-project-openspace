import { createAppKit } from "@reown/appkit/react";

import { WagmiProvider } from "wagmi";
import { sepolia, mainnet, AppKitNetwork } from "@reown/appkit/networks";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiAdapter } from "@reown/appkit-adapter-wagmi";
import { SolanaAdapter } from "@reown/appkit-adapter-solana";
import {
  SolflareWalletAdapter,
  PhantomWalletAdapter
} from "@solana/wallet-adapter-wallets";
import anvilNetwork from "./anvilNetwork";


const queryClient = new QueryClient();

// 1. Get projectId from https://cloud.reown.com
export const projectId = "5b02282c5390cbb75622cc86c78eed4d";

// 2. Create a metadata object - optional
const metadata = {
  name: "AppKit",
  description: "AppKit Example",
  url: "https://example.com", // origin must match your domain & subdomain
  icons: ["https://avatars.githubusercontent.com/u/179229932"]
};

// 3. Set the networks
const networks: [AppKitNetwork, ...AppKitNetwork[]] = [
  anvilNetwork,
  sepolia,
  mainnet
];

const solanaWeb3JsAdapter = new SolanaAdapter({
  wallets: [new PhantomWalletAdapter(), new SolflareWalletAdapter()]
});

// 4. Create Wagmi Adapter
const wagmiAdapter = new WagmiAdapter({
  networks,
  projectId,
  ssr: true
});

// 5. Create modal
createAppKit({
  adapters: [wagmiAdapter, solanaWeb3JsAdapter],
  networks,
  projectId,
  metadata,
  features: {
    analytics: true // Optional - defaults to your Cloud configuration
  }
});

export default function AppKitProvider({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={wagmiAdapter.wagmiConfig}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProvider>
  );
}
