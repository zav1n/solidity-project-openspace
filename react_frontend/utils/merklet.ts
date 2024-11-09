import { MerkleTree } from "merkletreejs";
import { keccak256 } from "viem";

// 白名单用户地址
const whitelist = [
  "0x47C043311DB033833aCbE820187743432CfFDB71",
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906"
];

// 将地址哈希化以便用于生成Merkle树
const leafNodes = whitelist.map((addr) => keccak256(addr));
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

// 计算Merkle树根
const merkleRoot = merkleTree.getHexRoot();
console.log("Merkle Root:", merkleRoot);

// 为特定地址生成证明路径
const claimingAddress = "0x47C043311DB033833aCbE820187743432CfFDB71";
// const proof = merkleTree.getRoot().toString("hex");
const proof = merkleTree.getHexProof(keccak256(claimingAddress));
console.log("Proof for address:", claimingAddress, proof);

/** result 
 
  Merkle Root: 0xcab8ba485d057231b1e8c65c05bcfe592c8f9bc592a8b6502d994c65c1ad58be
  Proof for address: 0x47C043311DB033833aCbE820187743432CfFDB71 
  [
    '0x00314e565e0574cb412563df634608d76f5c59d9f817e85966100ec1d48005c0',
    '0x7e0eefeb2d8740528b8f598997a219669f0842302d3c573e9bb7262be3387e63'
  ]

 */