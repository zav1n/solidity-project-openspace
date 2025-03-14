require('dotenv').config();
require("hardhat-secure-accounts");

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.20",
  paths: {
    artifacts: "./artifacts"
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      chainId: 11155111,
      secureAccounts: {
        enabled: true,
        defaultAccount: "948e"
      }
    }
  }
};

