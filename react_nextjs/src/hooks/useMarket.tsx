import { useState } from "react";
import { useReadContract } from "wagmi";
import { getSignature } from "@/axios/api/marketApi"
import {
  NFT_MARKETPLACE_ADDRESS,
  PERMIT_BUY_ABI
} from "../utils/contracts";

export function useNFTMarket() {
  const [error, setError] = useState<unknown>(null);
  // const { writeContract } = useWriteContract();
  const permitBuyNFT = async (buyer: string, tokenId: number) => {
    try {
      const { nonce, deadline, v, r, s } = await getSignature({
        buyer,
        tokenId
      });
      // const { nonce, deadline, v, r, s } = data;

      const result = await useReadContract({
        abi: PERMIT_BUY_ABI,
        address: NFT_MARKETPLACE_ADDRESS as `0x${string}`,
        functionName: "permitBuy",
        args: [tokenId, nonce, deadline, v, r, s]
      });

      console.warn(result)

      
    } catch (error) {
      setError(error);
      throw error;
    }
    return error
  };
  return {
    permitBuyNFT,
    error
  };
}
