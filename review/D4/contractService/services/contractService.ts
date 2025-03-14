import * as ethers from 'ethers';
import OpenspaceNFTArtifact from '../artifacts/contracts/OpenspaceNFT.sol/OpenspaceNFT.json';

// 合约地址 - 部署后需要更新
export const CONTRACT_ADDRESS = '0x7327C58514E4A82904Af849e3865E54ABD9C8e89'; // 本地Hardhat网络的默认第一个部署地址

export interface NFTMetadata {
  name?: string;
  description?: string;
  image?: string;
  attributes?: Array<{
    trait_type: string;
    value: string | number;
  }>;
}

export interface NFT {
  id: number;
  tokenURI: string;
  metadata?: NFTMetadata;
}

// 获取合约实例
export const getContract = (signer?: ethers.Signer) => {
  if (!window.ethereum) throw new Error('未检测到以太坊提供者');
  
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  return new ethers.Contract(
    CONTRACT_ADDRESS,
    OpenspaceNFTArtifact.abi,
    signer || provider
  );
};

// 铸造NFT
export const mintNFT = async () => {
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const contract = getContract(signer);
  
  // 获取铸造价格
  const mintPrice = await contract.mintPrice();
  
  // 铸造NFT
  const tx = await contract.mint({
    value: mintPrice
  });
  
  // 等待交易确认
  const receipt = await tx.wait();
  
  // 从事件中获取tokenId
  const event = receipt.events?.find(event => event.event === 'Transfer');
  const tokenId = event?.args?.tokenId?.toNumber();
  
  return {
    transactionHash: tx.hash,
    tokenId
  };
};

// 获取用户拥有的NFT
export const getUserNFTs = async (address: string): Promise<NFT[]> => {
  const contract = getContract();
  
  // 获取用户的NFT余额
  const balance = await contract.balanceOf(address);
  const balanceNumber = balance.toNumber();
  
  if (balanceNumber === 0) {
    return [];
  }
  
  // 获取用户拥有的所有NFT
  const userNFTs: NFT[] = [];
  
  for (let i = 0; i < balanceNumber; i++) {
    // 获取tokenId
    const tokenId = await contract.tokenOfOwnerByIndex(address, i);
    const id = tokenId.toNumber();
    
    // 获取tokenURI
    const tokenURI = await contract.tokenURI(id);
    
    const nft: NFT = { id, tokenURI };
    
    // 尝试获取元数据
    try {
      if (tokenURI.startsWith('http')) {
        const response = await fetch(tokenURI);
        const metadata = await response.json();
        nft.metadata = metadata;
      }
    } catch (metadataError) {
      console.error(`获取NFT #${id}元数据失败:`, metadataError);
    }
    
    userNFTs.push(nft);
  }
  
  return userNFTs;
};

// 获取铸造价格
export const getMintPrice = async (): Promise<string> => {
  const contract = getContract();
  const price = await contract.mintPrice();
  return ethers.utils.formatEther(price);
};
