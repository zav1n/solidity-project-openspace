import { useState } from "react";
import { providers, ethers } from "ethers";
import { FlashbotsBundleProvider } from "@flashbots/ethers-provider-bundle";
import { signer2 } from "../../utils/keystore";

export default function FlashBoot() {
  const [pwd, setPwd] = useState("");

  const provider = new providers.JsonRpcProvider("https://rpc2.sepolia.org");

  const execute = async () => {
    try {
      // 获取私钥
      const w = await ethers.Wallet.fromEncryptedJson(
        JSON.stringify(signer2),
        pwd
      );

      // 使用私钥生成签名钱包
      const wallet = new ethers.Wallet(w.privateKey, provider);

      const openspaceNFTAddress = "0xDEb69dAd5003F14B3330D8C91A892D76509951e8";
      const abi = [
        {
          type: "function",
          name: "enablePresale",
          inputs: [],
          outputs: [],
          stateMutability: "nonpayable"
        }
        // {
        //   type: "function",
        //   name: "participateInPresale",
        //   inputs: [],
        //   outputs: [],
        //   stateMutability: "nonpayable",
        // },
      ];
      // 使用 Flashbots provider
      const flashbotsProvider = await FlashbotsBundleProvider.create(
        provider,
        wallet,
        "https://relay-sepolia.flashbots.net"
      );

      const openspaceNFT = new ethers.Contract(
        openspaceNFTAddress,
        abi,
        wallet
      );

      const bundleTransactions = [
        {
          signer: wallet,
          transaction: {
            to: openspaceNFTAddress,
            data: openspaceNFT.interface.encodeFunctionData("enablePresale"),
            chainId: 11155111,
            gasLimit: 100000,
            maxFeePerGas: ethers.utils.parseUnits("10", "gwei"),
            maxPriorityFeePerGas: ethers.utils.parseUnits("2", "gwei"),
            type: 2 // EIP-1559 transaction
          }
        }
        // {
        //   signer: wallet,
        //   transaction: {
        //     to: openspaceNFTAddress,
        //     data: openspaceNFT.interface.encodeFunctionData("participateInPresale"),
        //     chainId: 11155111,
        //     gasLimit: 100000,
        //     maxFeePerGas: ethers.parseUnits("10", "gwei"),
        //     maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"),
        //     type: 2, // EIP-1559 transaction
        //   },
        // },
      ];

      const bigNumberToString = (key: unknown, value: unknown) =>
        typeof value === "bigint" ? value.toString() : value;

      console.log(
        "Bundle transactions:",
        JSON.stringify(bundleTransactions, bigNumberToString, 2)
      );

      const blockNumber = await provider.getBlockNumber();

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
      alert(error);
    }
  };

  return (
    <>
      <div>
        <input
          type="text"
          placeholder="password"
          onChange={(e) => setPwd(e.target.value)}
        />
        <button onClick={execute}>execute</button>
      </div>
    </>
  );
}
