import dotenv from "dotenv";
import { ethers } from "ethers";
import { signer2, signer3 } from "../../react_frontend/utils/keystore.ts";
import { FlashbotsBundleProvider } from "@flashbots/ethers-provider-bundle";

dotenv.config();
// const INFURA_PROJECT_ID = process.env.INFURA_PROJECT_ID;
// const PRIVATE_KEY = process.env.PRIVATE_KEY;
// const FLASHBOTS_RELAY_SIGNING_KEY = process.env.FLASHBOTS_RELAY_SIGNING_KEY;
const RPC_URL = "https://rpc.ankr.com/eth_sepolia";
const FLASHBOTS_ENDPOINT = "https://relay-sepolia.flashbots.net/";

const ABI = [
  "function owner() external view returns (address)",
  "function presale(uint256 amount) external payable",
  "function enablePresale() external"
];

async function main() {
  try {
    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);

    const s2 = await ethers.Wallet.fromEncryptedJson(
      JSON.stringify(signer2),
      "INPUT_PASSWORD"
    );
    const s3 = await ethers.Wallet.fromEncryptedJson(
      JSON.stringify(signer3),
      "INPUT_PASSWORD"
    );

    const s2pk = s2.privateKey.slice(2);
    const s3pk = s3.privateKey.slice(2);

    const ownerWallet = new ethers.Wallet(s2pk, provider);
    const minterWallet = new ethers.Wallet(s3pk, provider);

    const flashbotsProvider = await FlashbotsBundleProvider.create(
      provider,
      ownerWallet,
      FLASHBOTS_ENDPOINT
    );

    const nftContract = new ethers.Contract(
      "0x2521c6c1ed0a2598f55255e7b22fa3e85b704777",
      ABI,
      provider
    );

    const blockNumber = await provider.getBlockNumber();
    console.log(`Current block number: ${blockNumber}`);

    const ownerNonce = await provider.getTransactionCount(ownerWallet.address, "pending");
    const minterNonce = await provider.getTransactionCount(minterWallet.address, "pending");

    const enablePresaleTx = await nftContract.populateTransaction.enablePresale();
    const signedEnablePresaleTx = await ownerWallet.signTransaction({
      ...enablePresaleTx,
      nonce: ownerNonce,
      gasLimit: ethers.utils.hexlify(100000),
      gasPrice: ethers.utils.parseUnits("5", "gwei")
    });

    const presaleTx = await nftContract.populateTransaction.presale(ethers.utils.parseEther("0.01"));
    const signedPresaleTx = await minterWallet.signTransaction({
      ...presaleTx,
      nonce: minterNonce,
      gasLimit: ethers.utils.hexlify(200000),
      gasPrice: ethers.utils.parseUnits("5", "gwei"),
      value: ethers.utils.parseEther("0.01")
    });

    const bundle = [
      {
        signedTransaction: signedEnablePresaleTx
      },
      {
        signedTransaction: signedPresaleTx
      }
    ];

    const bundleResponse = await flashbotsProvider.sendBundle(bundle, blockNumber + 5);

    console.log("bundleResponse", bundleResponse);
    const resolution = await bundleResponse.wait();
    console.log("Bundle Resolution:", resolution);

    const receipts = await bundleResponse.receipts();
    console.log("Bundle receipts:", receipts);

    console.log(
      "EnablePresale 交易 Hash:",
      ethers.utils.keccak256(signedEnablePresaleTx)
    );
    console.log("Presale 交易 Hash:", ethers.utils.keccak256(signedPresaleTx));
  } catch (error) {
    console.error("Error during transaction processing:", error);
  }
}

main().catch((error) => {
  console.error("Main function error:", error);
  process.exit(1);
});
