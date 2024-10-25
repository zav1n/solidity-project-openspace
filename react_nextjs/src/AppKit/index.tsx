// context/index.tsx
"use client";

import { wagmiAdapter, projectId } from "@/AppKit/config";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { createAppKit } from "@reown/appkit/react";
import {
  mainnet,
  base,
  optimism,
  polygon,
  sepolia,
  solana,
  solanaTestnet,
  solanaDevnet
} from "@reown/appkit/networks";
import React, { type ReactNode } from "react";
import { cookieToInitialState, WagmiProvider, type Config } from "wagmi";

import { SolanaAdapter } from "@reown/appkit-adapter-solana";
import {
  SolflareWalletAdapter,
  PhantomWalletAdapter
} from "@solana/wallet-adapter-wallets";

// Set up queryClient
const queryClient = new QueryClient();

if (!projectId) {
  throw new Error("Project ID is not defined");
}

// Set up metadata
const metadata = {
  name: "web3Wallet-AppKit",
  description: "AppKit Example",
  url: "https://reown.com/appkit", // origin must match your domain & subdomain
  icons: ["https://assets.reown.com/reown-profile-pic.png"]
};

const solanaWeb3JsAdapter = new SolanaAdapter({
  wallets: [new PhantomWalletAdapter(), new SolflareWalletAdapter()]
});

// Create the modal
createAppKit({
  adapters: [wagmiAdapter, solanaWeb3JsAdapter],
  projectId,
  networks: [
    mainnet,
    sepolia,
    optimism,
    base,
    polygon,
    solana,
    solanaTestnet,
    solanaDevnet
  ],
  defaultNetwork: sepolia,
  metadata: metadata,
  features: {
    analytics: true // Optional - defaults to your Cloud configuration
  }
});

function ContextProvider({
  children,
  cookies
}: {
  children: ReactNode;
  cookies: string | null;
}) {
  const initialState = cookieToInitialState(
    wagmiAdapter.wagmiConfig as Config,
    cookies
  );

  return (
    <WagmiProvider
      config={wagmiAdapter.wagmiConfig as Config}
      initialState={initialState}
    >
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProvider>
  );
}

export default ContextProvider;
