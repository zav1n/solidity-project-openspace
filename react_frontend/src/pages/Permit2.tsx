// import React from "react";
import { walletClient, account } from "../AppKit/walletClient";
import { keccak256, stringToBytes } from "viem/utils";
const domain = {
  name: keccak256(stringToBytes("Permit2")),
  chainId: 1,
  verifyingContract: "0xa56f03C8B459a479Aea272CB7C1B454Fc3827BFb"
} as const;

// EIP712Domain(string name,uint256 chainId,address verifyingContract)
// PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)
// TokenPermissions(address token,uint256 amount)
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

const Permit2 = async () => {
  console.warn("account", account);
  const signature = await walletClient.signTypedData({
    account,
    domain,
    types,
    primaryType: "Mail",
    message: {
      from: {
        name: "Cow",
        wallet: "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"
      },
      to: {
        name: "Bob",
        wallet: "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
      },
      contents: "Hello, Bob!"
    }
  });
  return <div>Permit2</div>;
};

export default Permit2;
