import React, { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import { useWeb3React } from '@web3-react/core';

/**
 * Web3组件开发示例
 * 展示常见的Web3交互组件实现
 */

// ================ 1. 钱包连接组件 ================

/**
 * 钱包连接按钮组件
 * 处理钱包连接、断开连接和账户显示
 */
export const WalletConnectButton: React.FC = () => {
  const { activate, deactivate, active, account, error, chainId } = useWeb3React();
  const [connecting, setConnecting] = useState(false);
  
  // 连接MetaMask钱包
  const connectMetaMask = useCallback(async () => {
    if (connecting) return;
    setConnecting(true);
    
    try {
      // 检查是否安装了MetaMask
      if (!window.ethereum) {
        throw new Error('请安装MetaMask钱包');
      }
      
      // 请求连接
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      
      // 创建Web3注入器
      const injected = await import('@web3-react/injected-connector').then(
        module => new module.InjectedConnector({ supportedChainIds: [1, 3, 4, 5, 42, 56, 137] })
      );
      
      // 激活连接
      await activate(injected, undefined, true);
    } catch (err: any) {
      console.error('连接钱包失败:', err);
      alert(`连接钱包失败: ${err.message || '未知错误'}`);
    } finally {
      setConnecting(false);
    }
  }, [activate, connecting]);
  
  // 断开连接
  const disconnectWallet = useCallback(() => {
    try {
      deactivate();
    } catch (err) {
      console.error('断开钱包失败:', err);
    }
  }, [deactivate]);
  
  // 格式化地址显示
  const formatAddress = (address: string) => {
    return `${address.substring(0, 6)}...${address.substring(address.length - 4)}`;
  };
  
  // 获取当前网络名称
  const getNetworkName = (chainId: number | undefined) => {
    if (!chainId) return '未知网络';
    
    const networks: Record<number, string> = {
      1: '以太坊主网',
      3: 'Ropsten测试网',
      4: 'Rinkeby测试网',
      5: 'Goerli测试网',
      42: 'Kovan测试网',
      56: '币安智能链',
      137: 'Polygon'
    };
    
    return networks[chainId] || `链ID: ${chainId}`;
  };
  
  return (
    <div className="wallet-connect-button">
      {active && account ? (
        <div className="wallet-info">
          <div className="account-info">
            <div className="network-badge">{getNetworkName(chainId)}</div>
            <div className="address">{formatAddress(account)}</div>
          </div>
          <button 
            className="disconnect-button" 
            onClick={disconnectWallet}
          >
            断开连接
          </button>
        </div>
      ) : (
        <button 
          className="connect-button" 
          onClick={connectMetaMask} 
          disabled={connecting}
        >
          {connecting ? '连接中...' : '连接钱包'}
        </button>
      )}
      
      {error && <div className="error-message">{error.message}</div>}
    </div>
  );
};

// ================ 2. 代币余额组件 ================

/**
 * 代币余额显示组件
 * 显示用户的代币余额并处理余额更新
 */
interface TokenBalanceProps {
  tokenAddress: string;
  tokenSymbol: string;
  tokenDecimals?: number;
}

export const TokenBalance: React.FC<TokenBalanceProps> = ({ 
  tokenAddress, 
  tokenSymbol, 
  tokenDecimals = 18 
}) => {
  const { account, library } = useWeb3React();
  const [balance, setBalance] = useState<string>('0');
  const [loading, setLoading] = useState(false);
  
  // ERC20代币ABI
  const erc20Abi = [
    'function balanceOf(address owner) view returns (uint256)',
    'function decimals() view returns (uint8)',
    'function symbol() view returns (string)',
    'event Transfer(address indexed from, address indexed to, uint256 value)'
  ];
  
  // 获取代币余额
  const fetchBalance = useCallback(async () => {
    if (!account || !library || !tokenAddress) return;
    
    setLoading(true);
    
    try {
      const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, library);
      const rawBalance = await tokenContract.balanceOf(account);
      const formattedBalance = ethers.utils.formatUnits(rawBalance, tokenDecimals);
      setBalance(formattedBalance);
    } catch (err) {
      console.error('获取代币余额失败:', err);
      setBalance('0');
    } finally {
      setLoading(false);
    }
  }, [account, library, tokenAddress, tokenDecimals]);
  
  // 监听余额变化
  useEffect(() => {
    if (!account || !library || !tokenAddress) {
      setBalance('0');
      return;
    }
    
    // 初始加载余额
    fetchBalance();
    
    // 监听Transfer事件
    const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, library);
    const fromFilter = tokenContract.filters.Transfer(account, null);
    const toFilter = tokenContract.filters.Transfer(null, account);
    
    const onTransfer = () => {
      fetchBalance();
    };
    
    tokenContract.on(fromFilter, onTransfer);
    tokenContract.on(toFilter, onTransfer);
    
    return () => {
      tokenContract.off(fromFilter, onTransfer);
      tokenContract.off(toFilter, onTransfer);
    };
  }, [account, library, tokenAddress, fetchBalance]);
  
  // 格式化余额显示
  const formatBalance = (balance: string) => {
    const num = parseFloat(balance);
    if (num === 0) return '0';
    if (num < 0.0001) return '< 0.0001';
    return num.toLocaleString(undefined, { maximumFractionDigits: 4 });
  };
  
  return (
    <div className="token-balance">
      <div className="token-symbol">{tokenSymbol}</div>
      <div className="balance-value">
        {loading ? (
          <span className="loading">加载中...</span>
        ) : (
          <span>{formatBalance(balance)}</span>
        )}
      </div>
      <button className="refresh-button" onClick={fetchBalance} disabled={loading}>
        刷新
      </button>
    </div>
  );
};

// ================ 3. 合约交互组件 ================

/**
 * 合约交互组件
 * 提供通用的合约方法调用界面
 */
interface ContractInteractionProps {
  contractAddress: string;
  contractAbi: any[];
  methodName: string;
  methodInputs: Array<{
    name: string;
    type: string;
  }>;
  methodOutputs?: Array<{
    name: string;
    type: string;
  }>;
  isWrite?: boolean;
  buttonText?: string;
}

export const ContractInteraction: React.FC<ContractInteractionProps> = ({
  contractAddress,
  contractAbi,
  methodName,
  methodInputs,
  methodOutputs,
  isWrite = false,
  buttonText = '执行'
}) => {
  const { account, library } = useWeb3React();
  const [inputValues, setInputValues] = useState<Record<string, string>>({});
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [txHash, setTxHash] = useState<string | null>(null);
  
  // 处理输入变化
  const handleInputChange = (name: string, value: string) => {
    setInputValues(prev => ({
      ...prev,
      [name]: value
    }));
  };
  
  // 执行合约方法
  const executeMethod = async () => {
    if (!account || !library || !contractAddress) {
      setError('请先连接钱包');
      return;
    }
    
    setLoading(true);
    setError(null);
    setResult(null);
    setTxHash(null);
    
    try {
      // 准备参数
      const params = methodInputs.map(input => inputValues[input.name] || '');
      
      // 创建合约实例
      const contract = new ethers.Contract(
        contractAddress,
        contractAbi,
        isWrite ? library.getSigner() : library
      );
      
      if (isWrite) {
        // 写入方法
        const tx = await contract[methodName](...params);
        setTxHash(tx.hash);
        
        // 等待交易确认
        const receipt = await tx.wait();
        setResult({
          transactionHash: receipt.transactionHash,
          blockNumber: receipt.blockNumber,
          status: receipt.status === 1 ? '成功' : '失败'
        });
      } else {
        // 只读方法
        const result = await contract[methodName](...params);
        setResult(result);
      }
    } catch (err: any) {
      console.error('合约调用失败:', err);
      setError(err.message || '未知错误');
    } finally {
      setLoading(false);
    }
  };
  
  // 格式化结果显示
  const formatResult = (result: any) => {
    if (result === null) return null;
    
    if (typeof result === 'object' && result.transactionHash) {
      // 交易结果
      return (
        <div className="tx-result">
          <div>交易哈希: {result.transactionHash}</div>
          <div>区块: {result.blockNumber}</div>
          <div>状态: {result.status}</div>
        </div>
      );
    }
    
    if (Array.isArray(result)) {
      // 数组结果
      return (
        <div className="array-result">
          {result.map((item, index) => (
            <div key={index} className="array-item">
              {methodOutputs && methodOutputs[index]?.name}: {item.toString()}
            </div>
          ))}
        </div>
      );
    }
    
    // 单值结果
    if (ethers.BigNumber.isBigNumber(result)) {
      return result.toString();
    }
    
    return JSON.stringify(result);
  };
  
  return (
    <div className="contract-interaction">
      <h3>{methodName}</h3>
      
      <div className="method-inputs">
        {methodInputs.map(input => (
          <div key={input.name} className="input-field">
            <label>
              {input.name} ({input.type}):
              <input
                type="text"
                value={inputValues[input.name] || ''}
                onChange={(e) => handleInputChange(input.name, e.target.value)}
                placeholder={`输入 ${input.type}`}
              />
            </label>
          </div>
        ))}
      </div>
      
      <button 
        className="execute-button" 
        onClick={executeMethod} 
        disabled={loading || !account}
      >
        {loading ? '处理中...' : buttonText}
      </button>
      
      {error && (
        <div className="error-message">
          错误: {error}
        </div>
      )}
      
      {txHash && !result && (
        <div className="pending-tx">
          交易已提交: {txHash}
          <div className="spinner"></div>
        </div>
      )}
      
      {result !== null && (
        <div className="result-container">
          <h4>结果:</h4>
          <div className="result-value">{formatResult(result)}</div>
        </div>
      )}
    </div>
  );
};

// ================ 4. NFT展示组件 ================

/**
 * NFT展示组件
 * 显示用户拥有的NFT
 */
interface NFTDisplayProps {
  contractAddress: string;
  chainId?: number;
}

interface NFTMetadata {
  name: string;
  description: string;
  image: string;
  attributes?: Array<{
    trait_type: string;
    value: string;
  }>;
}

export const NFTDisplay: React.FC<NFTDisplayProps> = ({ contractAddress, chainId = 1 }) => {
  const { account, library } = useWeb3React();
  const [nfts, setNfts] = useState<Array<{ id: string; metadata: NFTMetadata | null }>>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  // ERC721 ABI
  const erc721Abi = [
    'function balanceOf(address owner) view returns (uint256)',
    'function tokenOfOwnerByIndex(address owner, uint256 index) view returns (