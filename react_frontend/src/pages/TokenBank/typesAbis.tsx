import { parseAbi } from "viem";
export const erc20ABI = parseAbi([
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function balanceOf(address account) external view returns (uint256)",
  "function allowance(address owner, address spender) public view returns (uint256)",
  "function approve(address spender, uint256 amount) external returns (bool)"
]);

export const depositWithPermit2ABI = parseAbi([
  "struct TokenPermissions { address token; uint256 amount; }",
  "struct PermitTransferFrom {TokenPermissions permitted; uint256 nonce; uint256 deadline; }",
  "function depositWithPermit2(address token,uint256 amount,PermitTransferFrom permit,bytes signature)"
]);

export const withDrawABI = parseAbi(["function withdraw(address token, uint256 amount)"]);
export const domain = {
  name: "Permit2",
  chainId: 11155111n,
  verifyingContract: "0x000000000022D473030F116dDEE9F6B43aC78BA3" // permit2
} as const;

// bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
//     "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
// );

export const types = {
  EIP712Domain: [
    { name: "name", type: "string" },
    { name: "chainId", type: "uint256" },
    { name: "verifyingContract", type: "address" }
  ],
  TokenPermissions: [
    { name: "token", type: "address" },
    { name: "amount", type: "uint256" }
  ],
  PermitTransferFrom: [
    { name: "permitted", type: "TokenPermissions" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" }
  ]
} as const;
