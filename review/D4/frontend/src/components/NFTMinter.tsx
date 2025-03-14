import { useState, useEffect } from 'react';
import { useAccount, useBalance } from 'wagmi';
import * as ethers from 'ethers';
import { CONTRACT_ADDRESS } from '../../../contractService/services/contractService';
import { log } from 'console';

// 简化版ABI，只包含我们需要的函数
const ABI = [
  "function mint() public payable returns (uint256)",
  "function mintPrice() public view returns (uint256)",
  "function balanceOf(address owner) external view returns (uint256 balance)",
  "function ownerOf(uint256 tokenId) external view returns (address owner)",
  "function tokenURI(uint256 tokenId) external view returns (string memory)"
];

function NFTMinter() {
  const { address, isConnected } = useAccount();
  const { data: balance } = useBalance({ address });
  
  const [isLoading, setIsLoading] = useState(false);
  const [mintPrice, setMintPrice] = useState<string>('0.01');
  const [mintStatus, setMintStatus] = useState<'idle' | 'pending' | 'success' | 'error'>('idle');
  const [tokenId, setTokenId] = useState<number | null>(null);
  const [transactionHash, setTransactionHash] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    const fetchMintPrice = async () => {
      if (!window.ethereum) return;
      
      try {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const contract = new ethers.Contract(
          CONTRACT_ADDRESS,
          ABI,
          provider
        );
        
        const price = await contract.mintPrice();
        setMintPrice(ethers.utils.formatEther(price));
      } catch (error) {
        console.error('获取铸造价格失败:', error);
      }
    };
    
    if (isConnected) {
      fetchMintPrice();
    }
  }, [isConnected]);

  const handleMint = async () => {
    if (!window.ethereum || !address) return;
    
    setIsLoading(true);
    setMintStatus('pending');
    setErrorMessage(null);
    
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        ABI,
        signer
      );
      
      // 铸造NFT
      const tx = await contract.mint({
        value: ethers.utils.parseEther(mintPrice)
      });
      
      setTransactionHash(tx.hash);
      
      // 等待交易确认
      const receipt = await tx.wait();
      
      // 从事件中获取tokenId
      const tokenId = parseInt(receipt.events[0].topics[3], 16);
      
      setTokenId(tokenId);
      setMintStatus('success');
    } catch (error: any) {
      console.error('铸造NFT失败:', error);
      setMintStatus('error');
      setErrorMessage(error.message || '铸造NFT时发生未知错误');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="nft-minter">
      <h2>NFT铸造</h2>
      
      {isConnected ? (
        <div>
          <p>当前钱包: {address}</p>
          <p>钱包余额: {balance ? `${parseFloat(balance.formatted).toFixed(4)} ${balance.symbol}` : '加载中...'}</p>
          <p>铸造价格: {mintPrice} ETH</p>
          
          <button 
            onClick={handleMint} 
            disabled={isLoading || mintStatus === 'pending'}
            style={{
              padding: '10px 20px',
              backgroundColor: '#0066cc',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: isLoading ? 'not-allowed' : 'pointer',
              fontSize: '16px',
              marginTop: '10px'
            }}
          >
            {isLoading ? '铸造中...' : '铸造NFT'}
          </button>
          
          {mintStatus === 'pending' && (
            <div className="mint-status pending">
              <p>交易处理中...</p>
              {transactionHash && (
                <p>交易哈希: {transactionHash}</p>
              )}
            </div>
          )}
          
          {mintStatus === 'success' && (
            <div className="mint-status success">
              <p>🎉 铸造成功!</p>
              <p>Token ID: {tokenId}</p>
              {transactionHash && (
                <p>交易哈希: {transactionHash}</p>
              )}
            </div>
          )}
          
          {mintStatus === 'error' && (
            <div className="mint-status error">
              <p>❌ 铸造失败</p>
              <p>{errorMessage}</p>
            </div>
          )}
        </div>
      ) : (
        <p>请先连接钱包以铸造NFT</p>
      )}
    </div>
  );
}

export default NFTMinter;
