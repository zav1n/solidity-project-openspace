import { ethers } from "ethers";
import { FlashbotsBundleProvider } from "@flashbots/ethers-provider-bundle";
import { signer2, signer3 } from "../../utils/keystore";



const execute = async () => {
  // 配置
  const RPC_URL = "https://rpc.ankr.com/eth_sepolia";
  const FLASHBOTS_ENDPOINT = "https://relay-sepolia.flashbots.net/";
  let PRIVATE_KEY_OWNER; // 合约所有者
  let PRIVATE_KEY_USER; // 用户

  const CONTRACT_ADDRESS = "0xDDb5fFdd866d58996129b57Bee7AD21bDeeF8E42"; // 替换为你的合约地址
  const ABI = [
    "function enablePresale() external",
    "function presale(uint256 amount) external payable"
  ];

  try {
    // 获取私钥
    const w2 = await ethers.Wallet.fromEncryptedJson(
      JSON.stringify(signer2),
      "Aa123456@"
    );
    const w3 = await ethers.Wallet.fromEncryptedJson(
      JSON.stringify(signer3),
      "Aa123456@"
    );

    PRIVATE_KEY_OWNER = w2.privateKey;
    PRIVATE_KEY_USER = w3.privateKey;

    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    const walletOwner = new ethers.Wallet(PRIVATE_KEY_OWNER, provider);
    const walletUser = new ethers.Wallet(PRIVATE_KEY_USER, provider);

    const flashbotsProvider = await FlashbotsBundleProvider.create(
      provider,
      walletOwner,
      FLASHBOTS_ENDPOINT
    );

    const contractInterface = new ethers.utils.Interface(ABI);

    const presaleAmount = 2; // 用户购买数量
    const presaleValue = ethers.utils.parseEther(
      (0.01 * presaleAmount).toString()
    );

    const bundleTransactions = [
      {
        signer: walletOwner,
        transaction: {
          to: CONTRACT_ADDRESS,
          data: contractInterface.encodeFunctionData("enablePresale"),
          chainId: 11155111, // Sepolia
          gasLimit: 200000,
          maxFeePerGas: ethers.utils.parseUnits("100", "gwei"),
          maxPriorityFeePerGas: ethers.utils.parseUnits("20", "gwei"),
          type: 2 // EIP-1559 transaction
        }
      },
      {
        signer: walletUser,
        transaction: {
          to: CONTRACT_ADDRESS,
          data: contractInterface.encodeFunctionData("presale", [
            presaleAmount
          ]),
          chainId: 11155111, // Sepolia
          gasLimit: 200000,
          maxFeePerGas: ethers.utils.parseUnits("100", "gwei"),
          maxPriorityFeePerGas: ethers.utils.parseUnits("20", "gwei"),
          value: presaleValue,
          type: 2 // EIP-1559 transaction
        }
      }
    ];

    // 发送捆绑
    const signedBundle = await flashbotsProvider.signBundle(bundleTransactions);
    const response = await flashbotsProvider.sendRawBundle(
      signedBundle,
      0
    );
    if ("error" in response) {
      console.error("Error sending bundle:", response.error.message);
      return;
    }

    console.log("Bundle sent, bundleHash:", response.bundleHash);

    // 查询状态
    const stats = await flashbotsProvider.getBundleStats(
      response.bundleHash,
      0
    );
    console.log("Bundle stats:", stats);

  } catch (error) {
    console.error("Error executing the transaction:", error);
  }
};

execute();
