// import React from "react";
import { useEffect, useState } from "react";
import { useAccount, useSignTypedData, useConfig } from "wagmi";
import {
  readContract,
  waitForTransactionReceipt,
  writeContract
} from "@wagmi/core";
import {
  maxUint256,
  getAddress,
  parseEther,
  isAddress,
  formatEther,
  stringify
} from "viem";
import { erc20ABI, depositWithPermit2ABI, withDrawABI, domain, types } from "./typesAbis";
import { sepolia } from "@reown/appkit/networks";



export default function DepositWithPermit2() {
  const tokenBank = getAddress("0xf08212d4eae91985fdadb69077b4a5f24086513d");
  const loginAccount = useAccount();
  const config = useConfig();
  const { signTypedDataAsync } = useSignTypedData();

  // const chainId = loginAccount && loginAccount.chainId;
  const [msg, setMsg] = useState<string | null>(null);
  const [token, setToken] = useState<string>("");
  const [amount, setAmount] = useState(0n);
  // const [isPending, setIsPending] = useState(false);

  useEffect(() => {
    if (isAddress(token)) {
      readContract(config, {
        address: token,
        abi: erc20ABI,
        functionName: "allowance",
        args: [loginAccount.address!, domain.verifyingContract]
      });
    }
  }, [token]);



  const handleDeposit = async () => {
      try {
        if (token == null) return;
        if (!isAddress(token)) return;

        // 1. check allowance
        console.log("Please approve first");
        // send approve transaction
        const approveHash = await writeContract(config, {
          address: token!,
          abi: erc20ABI,
          functionName: "approve",
          args: [domain.verifyingContract, maxUint256]
        });
        console.log("approve hash", approveHash);
        const approveReceipt = await waitForTransactionReceipt(config, {
          hash: approveHash
        });
        console.log("approve receipt", approveReceipt);
        // wait for approve transaction
        // 2. sign permit
        const permit = {
          permitted: {
            token: token!,
            amount: BigInt(amount)
          },
          spender: tokenBank,
          nonce: BigInt(Math.ceil(new Date().getTime())),
          deadline: BigInt(Math.ceil(new Date().getTime() / 1000 + 3600))
        };

        console.log(`Please sign permit`);
        const signature = await signTypedDataAsync({
          types: types,
          primaryType: "PermitTransferFrom",
          message: permit,
          domain: domain
        });
        console.log(`Permit signature: ${signature}`);
        console.log("Please wait for deposit transaction");
        // 3. depositWithPermit2
        const hash = await writeContract(config, {
          address: tokenBank,
          abi: depositWithPermit2ABI,
          functionName: "depositWithPermit2",
          args: [token, amount, permit, signature]
        });
        console.log(hash);
        const receipt = await waitForTransactionReceipt(config, { hash });
        console.log("receipt", receipt);
        console.log(`Success: ${hash}`);
        setMsg(`hash: ${sepolia.blockExplorers.default.url}/tx/${hash}`);
      } catch (error) {
        alert("action fail, see console");
        console.error(error);
        if (error && (error as { shortMessage?: string }).shortMessage) {
          console.log(
            `Error: ${(error as { shortMessage?: string }).shortMessage}`
          );
        } else {
          console.log(`Error: ${stringify(error)}`);
        }
      }
  }

  const handleWithdraw = async () => {
    try {
      const hash = await writeContract(config, {
        address: tokenBank,
        abi: withDrawABI,
        functionName: "withdraw",
        args: [token, amount]
      });
      setMsg(`hash: ${sepolia.blockExplorers.default.url}/tx/${hash}`);
    } catch (error) {
      alert("action fail, see console");
    }
  }
  return (
    <>
      <input
        type="text"
        value={token}
        placeholder="token address"
        onChange={(e) => setToken(e.target.value)}
        style={{ width: "360px" }}
      />
      <input
        type="number"
        value={formatEther(amount)}
        placeholder="amount(ether)"
        onChange={(e) => setAmount(parseEther(e.target.value))}
      />
      <button onClick={handleDeposit}>Deposit (permit2)</button>
      <button onClick={handleWithdraw}>widthDraw</button>
      {msg && (
        <div style={{ border: "1px solid #ccc", padding: "10px", borderRadius: "8px", marginTop: "10px" }}>
          <span>{msg}</span>
        </div>
      )}
    </>
  );
};
