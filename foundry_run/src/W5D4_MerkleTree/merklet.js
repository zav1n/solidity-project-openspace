import { MerkleTree } from "merkletreejs";
import { keccak256 } from "viem";

// 白名单用户地址
const whitelist = [
  "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
  "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
  "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
  "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"
];

// 将地址哈希化以便用于生成Merkle树
const leafNodes = whitelist.map((addr) => keccak256(addr));
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

// 计算Merkle树根
const merkleRoot = merkleTree.getHexRoot();
console.log("Merkle Root:", merkleRoot);

// 为特定地址生成证明路径
const claimingAddress = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4";
// const proof = merkleTree.getRoot().toString("hex");
const proof = merkleTree.getHexProof(keccak256(claimingAddress));
console.log("Proof for address:", claimingAddress, proof);

/** result 
 
  Merkle Root: 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097

  Proof for address:
  0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
  [
    '0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb',
    '0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c'
  ]

   Proof toHex: eeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097
 */
