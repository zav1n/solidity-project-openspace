// import React from "react";
import { walletClient, account } from "../AppKit/walletClient";

const domain = {
  name: "Permit2",
  chainId: 11155111,
  verifyingContract: "0xa56f03C8B459a479Aea272CB7C1B454Fc3827BFb"
} as const;

// bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
//     "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
// );

const types = {
  EIP712Domain: [
    { name: "name", type: "string" },
    { name: "chainId", type: "uint256" },
    { name: "verifyingContract", type: "address" }
  ],
  PermitTransferFrom: [
    { name: "permitted", type: "TokenPermissions" },
    { name: "spender", type: "address" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" }
  ],
  TokenPermissions: [
    { name: "token", type: "address" },
    { name: "amount", type: "uint256" }
  ],
} as const;

const message = {
  permitted: {
    token: "0xa56f03C8B459a479Aea272CB7C1B454Fc3827BFb",
    amount: 1e18
  },
  spender: "TokenBankAddress",
  nonce: 0,
  deadline: Math.floor(Date.now() / 1000) + 10 * 60
};

const Permit2 = async () => {
  const signature = await walletClient.signTypedData({
    types,
    domain,
    primaryType: "PermitTransferFrom",
    message,
    
  });

  return <div>Permit2</div>;
};

export default Permit2;
