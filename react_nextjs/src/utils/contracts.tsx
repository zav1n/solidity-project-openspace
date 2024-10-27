export const NFT_MARKETPLACE_ADDRESS = "0x1bcc2a2f646b17360622097dcb8635f9ef4d5699";
export const PERMIT_BUY_ABI = [
  {
    inputs: [
      { name: "tokenId", type: "uint256" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
      { name: "v", type: "uint8" },
      { name: "r", type: "bytes32" },
      { name: "s", type: "bytes32" }
    ],
    name: "permitBuy",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  }
];
