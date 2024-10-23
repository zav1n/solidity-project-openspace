// simple
// run: tsx ./src/examples/signEIP191.ts

import { keccak256, toHex } from "viem";
console.log("Simple Hash:", keccak256(toHex("Hello, World!")));

import { hashMessage } from "viem";
const message = "Hello, World!";
// hash message with default encoding(EIP-191)
const messageHash = hashMessage(message);
console.log("Person_Sign Hash1:", messageHash); 

// hash message with EIP-191 encoding
import { Hex, stringToHex } from "viem";
function eip191EncodeAndHash(message: string): Hex {
  const prefix = `\x19Ethereum Signed Message:\n${message.length}`;
  const prefixedMessage = prefix + message;
  console.log("Prefixed Message:", prefixedMessage);
  return keccak256(stringToHex(prefixedMessage));
}
console.log("Person_Sign Hash2:", eip191EncodeAndHash(message));

// sign message
import { privateKeyToAccount } from "viem/accounts";

const account = privateKeyToAccount(
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
);
console.log("Address:", account.address); // Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

const signature = await account.signMessage({ message });
console.log("Signature:", signature);

import { isAddressEqual } from "viem";
import { recoverMessageAddress } from "viem";
const recoveredAddress = await recoverMessageAddress({
  message: message,
  signature: signature,
});

console.log("Recovered Address:", recoveredAddress);
const wantSigner = account.address;
const pass = isAddressEqual(recoveredAddress, wantSigner);
console.log("Valid Signature:", pass);
