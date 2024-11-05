import { useState } from "react";
import { publicClient } from "../AppKit/publicClient";
import {
  toHex,
  keccak256,
  hexToBigInt,
  slice,
  trim
} from "viem";

export default function Eth_getStorageAt() {
  const [storageAt, setStorageAt] = useState<Array<{
    index: number;
    user: `0x${string}`;
    startTime: bigint;
    amount: bigint;
  }>>([]);

  const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const getStorageAt = async (slot: bigint) => {
    const data = await publicClient.getStorageAt({
      address: contractAddress,
      slot: toHex(slot)
    });
    return data;
  }

  const getLock = async () => {
    const locklength = await getStorageAt(0n);
    if (locklength !== undefined) {
      const baseSlot = hexToBigInt(keccak256(toHex(0, { size: 32 })));
      for(let i = 0; i < hexToBigInt(locklength); i++) {
        /**
           struct LockInfo{
            address user; // address | address payable -> 20 bytes, 地址都是占据20字节
            uint64 startTime; // uint64 -> 8 bytes
            uint256 amount; // uint256 -> 32 bytes
          }
          在合约中push了11次
          [LockInfo,LockInfo,...] 长度为11
          LockInfo占了两个插槽, 为什么占了两个插槽?
          我们都知道一个插槽32字节,那么
          - user + startTime = 28 字节 (因为amount塞不进来, 还剩下4字节, 那就给0补上了)
          - amount 单独占据一个, 32字节
          所以占了两个插槽
         */

        //  startTime + user 占了一个
        const userAndStartTimeSlot = baseSlot + BigInt(i * 2);
        // amount 单独占据一个插槽, 还要加上前面被占的位置
        const amountSlot = userAndStartTimeSlot + BigInt(1);
        // 所以整个的逻辑是 amount + startTime + user
        const [userAndStartTimeHex, amountHex] = await Promise.all(
          [userAndStartTimeSlot, amountSlot].map(async (slot) => {
            return await getStorageAt(slot);
          })
        );
        const trimedUserAndStartTimeHex = trim(userAndStartTimeHex!);
        const startTimeHex = slice(trimedUserAndStartTimeHex, 0, 8); // uint64占前8个字节
        const userHex = slice(trimedUserAndStartTimeHex, 9); // address占后20个字节
        setStorageAt((prevItems) => [...prevItems, {
          index: i,
          user: userHex!,
          startTime: hexToBigInt(startTimeHex!),
          amount: hexToBigInt(amountHex!)
        }]);
      }
    }
  }
  return (
    <>
      <button onClick={getLock}>getStorageAt</button>
      {storageAt && (
        <div
          style={{
            border: "1px solid #ccc",
            padding: "10px",
            borderRadius: "8px",
            marginTop: "10px"
          }}
        >
          <div>
            {storageAt.map((item, index) => (
              <div key={index}>
                <p>Index: {item.index}</p>
                <p>User: {item.user}</p>
                <p>Start Time: {item.startTime.toString()}</p>
                <p>Amount: {item.amount.toString()}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </>
  );
}
