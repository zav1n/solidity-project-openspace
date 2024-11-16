require("dotenv").config();

const { ethers } = require("ethers");
const {
  FlashbotsBundleProvider
} = require("@flashbots/ethers-provider-bundle");

const INFURA_PROJECT_ID = process.env.INFURA_PROJECT_ID;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const FLASHBOTS_RELAY_SIGNING_KEY = process.env.FLASHBOTS_RELAY_SIGNING_KEY;

async function createProvider() {
  const providers = [
    `https://sepolia.infura.io/v3/${INFURA_PROJECT_ID}`,
    "https://rpc.ankr.com/eth_sepolia",
    "https://rpc2.sepolia.org"
  ];

  for (const url of providers) {
    try {
      const provider = new ethers.JsonRpcProvider(url);
      await provider.getNetwork();
      console.log("Connected to provider:", url);
      return provider;
    } catch (error) {
      console.error("Failed to connect to provider:", url, error.message);
    }
  }
  throw new Error("Failed to connect to any provider");
}

async function main() {
  try {
    const provider = await createProvider();
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

    const flashbotsProvider = await FlashbotsBundleProvider.create(
      provider,
      new ethers.Wallet(FLASHBOTS_RELAY_SIGNING_KEY),
      "https://relay-sepolia.flashbots.net"
    );

    const openspaceNFTAddress = "0x25CCd4f02a6921Ea92a434d609ab3CE097A7711d";
    const abi = [
      {
        type: "function",
        name: "startPresale",
        inputs: [],
        outputs: [],
        stateMutability: "nonpayable"
      },
      {
        type: "function",
        name: "participateInPresale",
        inputs: [],
        outputs: [],
        stateMutability: "nonpayable"
      }
    ];

    const openspaceNFT = new ethers.Contract(openspaceNFTAddress, abi, wallet);

    const blockNumber = await provider.getBlockNumber();
    console.log(`Current block number: ${blockNumber}`);

    const walletAddress = await wallet.getAddress();
    console.log(`Wallet address: ${walletAddress}`);

    const bundleTransactions = [
      {
        signer: wallet,
        transaction: {
          to: openspaceNFTAddress,
          data: openspaceNFT.interface.encodeFunctionData("startPresale"),
          chainId: 11155111,
          gasLimit: 100000,
          maxFeePerGas: ethers.parseUnits("10", "gwei"),
          maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"),
          type: 2 // EIP-1559 transaction
        }
      },
      {
        signer: wallet,
        transaction: {
          to: openspaceNFTAddress,
          data: openspaceNFT.interface.encodeFunctionData(
            "participateInPresale"
          ),
          chainId: 11155111,
          gasLimit: 100000,
          maxFeePerGas: ethers.parseUnits("10", "gwei"),
          maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"),
          type: 2 // EIP-1559 transaction
        }
      }
    ];

    // Helper function to convert BigNumbers to string
    const bigNumberToString = (key, value) =>
      typeof value === "bigint" ? value.toString() : value;

    console.log(
      "Bundle transactions:",
      JSON.stringify(bundleTransactions, bigNumberToString, 2)
    );

    const signedBundle = await flashbotsProvider.signBundle(bundleTransactions);

    const simulation = await flashbotsProvider.simulate(
      signedBundle,
      blockNumber + 1
    );
    if ("error" in simulation) {
      console.error("Simulation error:", simulation.error);
    } else {
      console.log(
        "Simulation results:",
        JSON.stringify(simulation, bigNumberToString, 2)
      );
    }

    const bundleResponse = await flashbotsProvider.sendBundle(
      bundleTransactions,
      blockNumber + 1
    );

    if ("error" in bundleResponse) {
      console.error("Error sending bundle:", bundleResponse.error);
      return;
    }

    console.log(
      "Bundle response:",
      JSON.stringify(bundleResponse, bigNumberToString, 2)
    );

    const bundleReceipt = await bundleResponse.wait();
    if (bundleReceipt === 1) {
      console.log("Bundle included in block");
    } else {
      console.log("Bundle not included");
    }

    const bundleStats = await flashbotsProvider.getBundleStats(
      bundleResponse.bundleHash,
      blockNumber + 1
    );
    console.log(
      "Bundle stats:",
      JSON.stringify(bundleStats, bigNumberToString, 2)
    );
  } catch (error) {
    console.error("Error during transaction processing:", error);
  }
}

main().catch((error) => {
  console.error("Main function error:", error);
  process.exit(1);
});
