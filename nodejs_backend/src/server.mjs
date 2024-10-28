import express from "express";
import cors from "cors";
import { ethers } from "ethers";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const KEY_STORE = process.env.KEY_STORE || null;
console.warn("KEY_STORE", KEY_STORE);
const { privateKey } = await ethers.Wallet.fromEncryptedJson(
  KEY_STORE,
  "Aa123456@"
);
const wallet = new ethers.Wallet(privateKey);

// Whitelist addresses
const whitelist = new Set(["0xa02e8d6fec0f376f568db5Fe42aBcFE0401066cd"]);

app.post("/sign", async (req, res) => {
  try {
    const { buyer, tokenId } = req.body;

    // Check whitelist
    if (!whitelist.has(buyer)) {
      return res.status(503).json({ code: 'ERROR_01', message: 'error: "Address not whitelisted"' });
    }

    const deadline = Math.floor(Date.now() / 1000) + 86400; // 24 hours
    const nonce = 0; // You should implement nonce tracking

    // Create the signature
    const domain = {
      name: "testNFT",
      version: "1",
      chainId: 1, // Update with your chain ID
      verifyingContract: "0x1BCC2A2f646b17360622097DCB8635F9EF4D5699" // Your marketplace contract address
    };

    const types = {
      Permit: [
        { name: "buyer", type: "address" },
        { name: "market", type: "address" },
        { name: "tokenId", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" }
      ]
    };

    const value = {
      buyer,
      market: domain.verifyingContract,
      tokenId,
      nonce,
      deadline
    };

    const signature = await wallet._signTypedData(domain, types, value);
    const { v, r, s } = ethers.utils.splitSignature(signature);

    res.json({
      v,
      r,
      s,
      deadline,
      nonce
    });
  } catch (error) {
    console.error("Error signing message:", error);
    res.status(500).json({ error: "Failed to sign message" });
  }
});

app.post("/addWhitelist", async (req, res) => {
  try {
    const { address } = req.body;
    whitelist.add(address);
    res.status(200).json({ code: "200", data: whitelist, message: "add whitelist success"});
  } catch (error) {
    
  }

})

const PORT = process.env.PORT || 8001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
