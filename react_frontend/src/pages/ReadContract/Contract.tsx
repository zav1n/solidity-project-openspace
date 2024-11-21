import { useState } from 'react';
import { ethers } from 'ethers';
import { signer2 } from "../../../utils/keystore";

const rpcUrl = import.meta.env.VITE_INFURA_SEPOLIA_RPC;
const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
const tokenAddr = "0xab532963a8bdc1870a7472d4add9d9592c6bc69c";
const ABI = [
  "function balanceOf(address account) external view returns (uint256)",
  "function totalSupply() external view returns (uint256)",
];

export default function Contract() {
  const [pwd, setPwd] = useState("");
  const [balance, setBalance] = useState("");
  const [totalSupply, setTotalSupply] = useState("");
  const connect = async () => {
    try {
      const w = await ethers.Wallet.fromEncryptedJson(
        JSON.stringify(signer2),
        pwd
      );
      const wallet = new ethers.Wallet(w.privateKey, provider);
      const contract = new ethers.Contract(tokenAddr, ABI, wallet);

      const tokenBalance = await contract.balanceOf(w.address);
      const tokenTotalSupply = await contract.totalSupply();
      setTotalSupply(ethers.utils.formatEther(tokenTotalSupply));
      setBalance(ethers.utils.formatEther(tokenBalance));
    } catch (error) {
      alert(`connect error ${error}`);
    }
  }
  return (
    <>
      <input onChange={(e) => setPwd(e.target.value)} />
      <button onClick={connect}>ethers Connect</button>
      <div>{balance}</div>
      <div>{totalSupply}</div>
    </>
  );
}