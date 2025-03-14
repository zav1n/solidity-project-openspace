import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import * as ethers from 'ethers';
import OpenspaceNFTArtifact from '../../../contractService/artifacts/contracts/OpenspaceNFT.sol/OpenspaceNFT.json';
import { CONTRACT_ADDRESS } from "../../../contractService/services/contractService";

interface NFT {
  id: number;
  tokenURI: string;
  metadata?: {
    name?: string;
    description?: string;
    image?: string;
  };
}

function NFTGallery() {
  const { address, isConnected } = useAccount();
  const [nfts, setNfts] = useState<NFT[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchNFTs = async () => {
      if (!window.ethereum || !address || !isConnected) return;
      
      setIsLoading(true);
      setError(null);
      
      try {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const contract = new ethers.Contract(
          CONTRACT_ADDRESS,
          OpenspaceNFTArtifact.abi,
          provider
        );
        
        // 获取用户的NFT余额
        const balance = await contract.balanceOf(address);
        const balanceNumber = balance.toNumber();
        
        if (balanceNumber === 0) {
          setNfts([]);
          return;
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
        
        setNfts(userNFTs);
      } catch (error) {
        console.error('获取NFT失败:', error);
        setError('获取您的NFT时发生错误。请确保您已连接到正确的网络。');
      } finally {
        setIsLoading(false);
      }
    };
    
    fetchNFTs();
  }, [address, isConnected]);

  return (
    <div className="nft-gallery">
      <h2>我的NFT收藏</h2>
      
      {isConnected ? (
        <>
          {isLoading ? (
            <p>加载中...</p>
          ) : error ? (
            <p className="error">{error}</p>
          ) : nfts.length === 0 ? (
            <p>您还没有任何NFT。前往铸造页面获取您的第一个NFT！</p>
          ) : (
            <div className="nft-grid">
              {nfts.map((nft) => (
                <div key={nft.id} className="nft-card">
                  <h3>NFT #{nft.id}</h3>
                  {nft.metadata?.image && (
                    <img 
                      src={nft.metadata.image} 
                      alt={`NFT #${nft.id}`} 
                      style={{ maxWidth: '100%', height: 'auto' }}
                    />
                  )}
                  {nft.metadata?.name && <p><strong>名称:</strong> {nft.metadata.name}</p>}
                  {nft.metadata?.description && <p><strong>描述:</strong> {nft.metadata.description}</p>}
                  <p><strong>Token URI:</strong> {nft.tokenURI}</p>
                </div>
              ))}
            </div>
          )}
        </>
      ) : (
        <p>请先连接钱包以查看您的NFT</p>
      )}
    </div>
  );
}

export default NFTGallery;
