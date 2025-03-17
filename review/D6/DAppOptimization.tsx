import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { ethers } from 'ethers';
import { useWeb3React } from '@web3-react/core';
import { Contract } from '@ethersproject/contracts';

/**
 * DApp优化示例
 * 展示前端优化技术以提升Web3应用用户体验
 */

// ================ 1. Meta Transactions (无Gas交易) ================

/**
 * Meta交易签名器
 * 允许用户签名消息而非直接发送交易，由中继器支付Gas
 */
export function useMetaTransactions(contractAddress: string, abi: any) {
  const { library, account, chainId } = useWeb3React();
  
  // 创建合约实例
  const contract = useMemo(() => {
    if (!library || !contractAddress) return null;
    return new Contract(contractAddress, abi, library.getSigner());
  }, [library, contractAddress, abi]);
  
  // 准备元交易
  const prepareMetaTransaction = useCallback(
    async (functionName: string, args: any[]) => {
      if (!contract || !account || !chainId) return null;
      
      // 获取nonce
      const nonce = await contract.getNonce(account);
      
      // 创建要签名的数据
      const functionSignature = contract.interface.encodeFunctionData(functionName, args);
      
      // 创建签名消息
      const message = ethers.utils.solidityKeccak256(
        ['address', 'address', 'uint256', 'bytes', 'uint256'],
        [account, contractAddress, nonce, functionSignature, chainId]
      );
      
      // 签名消息
      const signature = await library.getSigner().signMessage(ethers.utils.arrayify(message));
      
      return {
        from: account,
        functionSignature,
        signature,
      };
    },
    [contract, account, chainId, library, contractAddress]
  );
  
  // 执行元交易
  const executeMetaTransaction = useCallback(
    async (functionName: string, args: any[]) => {
      const metaTx = await prepareMetaTransaction(functionName, args);
      if (!metaTx) throw new Error('Failed to prepare meta transaction');
      
      // 这里通常会调用后端中继服务
      // 示例: 直接调用合约的executeMetaTransaction方法
      return contract.executeMetaTransaction(
        metaTx.from,
        metaTx.functionSignature,
        metaTx.signature
      );
    },
    [contract, prepareMetaTransaction]
  );
  
  return { executeMetaTransaction };
}

// ================ 2. 批量交易优化 ================

/**
 * 批量交易处理器
 * 将多个交易合并为一个，减少用户确认次数和总Gas成本
 */
export function useBatchTransactions(multicallAddress: string) {
  const { library, account } = useWeb3React();
  
  // 创建Multicall合约实例
  const multicall = useMemo(() => {
    if (!library || !multicallAddress) return null;
    
    // Multicall ABI (简化版)
    const multicallAbi = [
      'function aggregate(tuple(address target, bytes callData)[] calls) returns (uint256 blockNumber, bytes[] returnData)'
    ];
    
    return new Contract(multicallAddress, multicallAbi, library.getSigner());
  }, [library, multicallAddress]);
  
  // 准备批量调用
  const batchCalls = useCallback(
    async (calls: { target: string; abi: any; functionName: string; args: any[] }[]) => {
      if (!multicall || !account) return null;
      
      // 编码每个调用
      const callData = calls.map((call) => {
        const contract = new ethers.utils.Interface(call.abi);
        const encodedData = contract.encodeFunctionData(call.functionName, call.args);
        
        return {
          target: call.target,
          callData: encodedData,
        };
      });
      
      // 执行批量调用
      const { blockNumber, returnData } = await multicall.aggregate(callData);
      
      // 解码结果
      return calls.map((call, i) => {
        const contract = new ethers.utils.Interface(call.abi);
        return contract.decodeFunctionResult(call.functionName, returnData[i]);
      });
    },
    [multicall, account]
  );
  
  return { batchCalls };
}

// ================ 3. 链下数据与链上数据结合 ================

/**
 * 混合数据加载器
 * 结合链上数据和链下索引数据，提高加载速度
 */
export function useHybridDataLoader(contractAddress: string, abi: any, subgraphUrl: string) {
  const { library } = useWeb3React();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<any>(null);
  
  // 创建合约实例
  const contract = useMemo(() => {
    if (!library || !contractAddress) return null;
    return new Contract(contractAddress, abi, library);
  }, [library, contractAddress, abi]);
  
  // 加载数据
  const loadData = useCallback(
    async (entityId: string) => {
      if (!contract || !subgraphUrl) return null;
      
      setLoading(true);
      
      try {
        // 并行加载链上和链下数据
        const [onChainData, offChainData] = await Promise.all([
          // 从合约加载关键数据
          (async () => {
            const owner = await contract.ownerOf(entityId);
            const tokenURI = await contract.tokenURI(entityId);
            return { owner, tokenURI };
          })(),
          
          // 从TheGraph加载历史和统计数据
          (async () => {
            const query = `{
              token(id: "${entityId}") {
                id
                createdAt
                transfers {
                  from
                  to
                  timestamp
                }
                lastPrice
                totalTransfers
              }
            }`;
            
            const response = await fetch(subgraphUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ query }),
            });
            
            const result = await response.json();
            return result.data.token;
          })(),
        ]);
        
        // 合并数据
        const combinedData = {
          ...onChainData,
          ...offChainData,
        };
        
        setData(combinedData);
      } catch (error) {
        console.error('Error loading hybrid data:', error);
      } finally {
        setLoading(false);
      }
    },
    [contract, subgraphUrl]
  );
  
  return { loading, data, loadData };
}

// ================ 4. 状态缓存与优化 ================

/**
 * 智能缓存管理器
 * 缓存链上数据并智能更新，减少RPC调用
 */
export function useSmartCache(cacheKey: string, fetchFn: () => Promise<any>, ttlMs = 30000) {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [lastUpdated, setLastUpdated] = useState(0);
  
  // 从本地存储加载缓存数据
  useEffect(() => {
    try {
      const cachedData = localStorage.getItem(`web3_cache_${cacheKey}`);
      if (cachedData) {
        const { data: storedData, timestamp } = JSON.parse(cachedData);
        if (Date.now() - timestamp < ttlMs) {
          setData(storedData);
          setLastUpdated(timestamp);
        }
      }
    } catch (err) {
      console.error('Error loading from cache:', err);
    }
  }, [cacheKey, ttlMs]);
  
  // 加载数据
  const loadData = useCallback(
    async (force = false) => {
      // 如果数据已经存在且未过期，且不是强制刷新，则跳过
      if (!force && data && Date.now() - lastUpdated < ttlMs) {
        return data;
      }
      
      setLoading(true);
      setError(null);
      
      try {
        const freshData = await fetchFn();
        setData(freshData);
        
        const timestamp = Date.now();
        setLastUpdated(timestamp);
        
        // 更新缓存
        localStorage.setItem(
          `web3_cache_${cacheKey}`,
          JSON.stringify({ data: freshData, timestamp })
        );
        
        return freshData;
      } catch (err: any) {
        setError(err);
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [data, lastUpdated, ttlMs, fetchFn, cacheKey]
  );
  
  return { data, loading, error, loadData, lastUpdated };
}

// ================ 5. 用户体验组件示例 ================

/**
 * 交易确认组件
 * 提供友好的交易状态反馈
 */
export const TransactionConfirmation: React.FC<{
  txHash: string;
  onConfirmed?: () => void;
}> = ({ txHash, onConfirmed }) => {
  const { library } = useWeb3React();
  const [status, setStatus] = useState('pending');
  const [confirmations, setConfirmations] = useState(0);
  
  useEffect(() => {
    if (!library || !txHash) return;
    
    const checkTransaction = async () => {
      try {
        const tx = await library.getTransaction(txHash);
        if (!tx) {
          setStatus('not_found');
          return;
        }
        
        const receipt = await library.getTransactionReceipt(txHash);
        if (!receipt) {
          setStatus('mining');
          return;
        }
        
        if (receipt.status === 1) {
          setStatus('success');
          setConfirmations(receipt.confirmations);
          if (receipt.confirmations >= 1 && onConfirmed) {
            onConfirmed();
          }
        } else {
          setStatus('failed');
        }
      } catch (error) {
        console.error('Error checking transaction:', error);
        setStatus('error');
      }
    };
    
    // 立即检查一次
    checkTransaction();
    
    // 设置轮询
    const interval = setInterval(checkTransaction, 3000);
    
    return () => clearInterval(interval);
  }, [library, txHash, onConfirmed]);
  
  // 状态显示
  const renderStatus = () => {
    switch (status) {
      case 'pending':
        return (
          <div className="tx-status pending">
            <div className="spinner"></div>
            <p>等待交易被发送到网络...</p>
          </div>
        );
      case 'mining':
        return (
          <div className="tx-status mining">
            <div className="spinner"></div>
            <p>交易确认中...</p>
          </div>
        );
      case 'success':
        return (
          <div className="tx-status success">
            <div className="icon">✓</div>
            <p>交易成功! ({confirmations} 确认)</p>
            <a 
              href={`https://etherscan.io/tx/${txHash}`}
              target="_blank"
              rel="noopener noreferrer"
            >
              在区块浏览器中查看
            </a>
          </div>
        );
      case 'failed':
        return (
          <div className="tx-status failed">
            <div className="icon">✗</div>
            <p>交易失败</p>
            <a 
              href={`https://etherscan.io/tx/${txHash}`}
              target="_blank"
              rel="noopener noreferrer"
            >
              在区块浏览器中查看详情
            </a>
          </div>
        );
      case 'not_found':
        return (
          <div className="tx-status not-found">
            <p>交易未找到，请稍后再试</p>
          </div>
        );
      case 'error':
        return (
          <div className="tx-status error">
            <p>检查交易状态时出错</p>
          </div>
        );
      default:
        return null;
    }
  };
  
  return renderStatus();
};

/**
 * DApp优化示例组件
 * 整合所有优化演示
 */
export const DAppOptimizationExample: React.FC = () => {
  const { library, account } = useWeb3React();
  const [currentTxHash, setCurrentTxHash] = useState<string | null>(null);
  
  const handleSendTransaction = async () => {
    if (!library || !account) return;
    
    try {
      // 创建一个简单的ETH转账交易
      const tx = await library.getSigner().sendTransaction({
        to: ethers.constants.AddressZero, // 示例地址
        value: ethers.utils.parseEther('0.001'),
      });
      
      setCurrentTxHash(tx.hash);
    } catch (error) {
      console.error('Transaction error:', error);
    }
  };
  
  return (
    <div className="dapp-optimization-example">
      <div className="transaction-confirmation">
        <h4>交易状态演示</h4>
        <button onClick={handleSendTransaction} className="action-button">
          发送模拟交易
        </button>
        {currentTxHash && <TransactionConfirmation txHash={currentTxHash} />}
      </div>
      
      <div className="section">
        <h4>Meta交易演示 (无Gas交易)</h4>
        <p>允许用户签名消息而非直接发送交易，由中继器支付Gas费用</p>
        <MetaTransactionDemo />
      </div>
      
      <div className="section">
        <h4>批量交易优化</h4>
        <p>将多个交易合并为一个，减少用户确认次数和总Gas成本</p>
        <BatchTransactionDemo />
      </div>
      
      <div className="section">
        <h4>混合数据加载</h4>
        <p>结合链上数据和链下索引数据，提高加载速度</p>
        <HybridDataDemo />
      </div>
      
      <div className="section">
        <h4>智能缓存管理</h4>
        <p>缓存链上数据并智能更新，减少RPC调用</p>
        <SmartCacheDemo />
      </div>
    </div>
  );
};

/**
 * Meta交易演示组件
 */
const MetaTransactionDemo: React.FC = () => {
  const { account } = useWeb3React();
  const [status, setStatus] = useState<string | null>(null);
  
  // 模拟合约地址和ABI
  const contractAddress = '0x1234567890123456789012345678901234567890';
  const abi = [
    'function getNonce(address user) view returns (uint256)',
    'function executeMetaTransaction(address userAddress, bytes functionSignature, bytes signature) returns (bytes)'
  ];
  
  const { executeMetaTransaction } = useMetaTransactions(contractAddress, abi);
  
  const handleMetaTransaction = async () => {
    if (!account) {
      setStatus('请先连接钱包');
      return;
    }
    
    setStatus('准备元交易...');
    
    try {
      // 模拟调用合约的transfer方法
      const result = await executeMetaTransaction('transfer', [
        '0x0000000000000000000000000000000000000001', // 接收地址
        ethers.utils.parseEther('1.0') // 金额
      ]);
      
      setStatus('元交易已发送，等待确认...');
      console.log('Meta transaction result:', result);
    } catch (error) {
      console.error('Meta transaction error:', error);
      setStatus('元交易失败');
    }
  };
  
  return (
    <div className="meta-transaction-demo">
      <button onClick={handleMetaTransaction} disabled={!account}>
        执行元交易
      </button>
      {status && <p className="status">{status}</p>}
    </div>
  );
};

/**
 * 批量交易演示组件
 */
const BatchTransactionDemo: React.FC = () => {
  const { account } = useWeb3React();
  const [results, setResults] = useState<any[] | null>(null);
  const [loading, setLoading] = useState(false);
  
  // 模拟Multicall合约地址
  const multicallAddress = '0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696';
  
  const { batchCalls } = useBatchTransactions(multicallAddress);
  
  const handleBatchCall = async () => {
    if (!account) return;
    
    setLoading(true);
    setResults(null);
    
    try {
      // 模拟批量调用多个合约的balanceOf方法
      const tokenAddresses = [
        '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI
        '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC
        '0xdAC17F958D2ee523a2206206994597C13D831ec7'  // USDT
      ];
      
      const erc20Abi = [
        'function balanceOf(address owner) view returns (uint256)'
      ];
      
      const calls = tokenAddresses.map(address => ({
        target: address,
        abi: erc20Abi,
        functionName: 'balanceOf',
        args: [account]
      }));
      
      const batchResults = await batchCalls(calls);
      
      // 格式化结果
      const formattedResults = batchResults?.map((result, index) => ({
        token: ['DAI', 'USDC', 'USDT'][index],
        balance: ethers.utils.formatUnits(
          result[0],
          [18, 6, 6][index] // 对应的小数位数
        )
      }));
      
      setResults(formattedResults);
    } catch (error) {
      console.error('Batch call error:', error);
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="batch-transaction-demo">
      <button onClick={handleBatchCall} disabled={!account || loading}>
        {loading ? '加载中...' : '批量查询代币余额'}
      </button>
      
      {results && (
        <div className="results">
          <h5>查询结果:</h5>
          <ul>
            {results.map((item, index) => (
              <li key={index}>
                {item.token}: {item.balance}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

/**
 * 混合数据加载演示组件
 */
const HybridDataDemo: React.FC = () => {
  const [tokenId, setTokenId] = useState('');
  
  // 模拟合约地址、ABI和Subgraph URL
  const contractAddress = '0x1234567890123456789012345678901234567890';
  const abi = [
    'function ownerOf(uint256 tokenId) view returns (address)',
    'function tokenURI(uint256 tokenId) view returns (string)'
  ];
  const subgraphUrl = 'https://api.thegraph.com/subgraphs/name/example/nft-subgraph';
  
  const { loading, data, loadData } = useHybridDataLoader(contractAddress, abi, subgraphUrl);
  
  const handleLoadData = () => {
    if (!tokenId) return;
    loadData(tokenId);
  };
  
  return (
    <div className="hybrid-data-demo">
      <div className="input-group">
        <input
          type="text"
          value={tokenId}
          onChange={(e) => setTokenId(e.target.value)}
          placeholder="输入Token ID"
        />
        <button onClick={handleLoadData} disabled={!tokenId || loading}>
          {loading ? '加载中...' : '加载数据'}
        </button>
      </div>
      
      {data && (
        <div className="data-display">
          <h5>混合数据结果:</h5>
          <p><strong>所有者:</strong> {data.owner}</p>
          <p><strong>Token URI:</strong> {data.tokenURI}</p>
          <p><strong>创建时间:</strong> {new Date(data.createdAt * 1000).toLocaleString()}</p>
          <p><strong>最后价格:</strong> {data.lastPrice ? ethers.utils.formatEther(data.lastPrice) + ' ETH' : 'N/A'}</p>
          <p><strong>总转移次数:</strong> {data.totalTransfers}</p>
        </div>
      )}
    </div>
  );
};

/**
 * 智能缓存演示组件
 */
const SmartCacheDemo: React.FC = () => {
  const [address, setAddress] = useState('');
  
  // 模拟获取ETH余额的函数
  const fetchBalance = useCallback(async () => {
    if (!address) throw new Error('地址不能为空');
    
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 返回模拟数据
    return {
      address,
      balance: '10.5 ETH',
      txCount: 42,
      lastUpdated: new Date().toISOString()
    };
  }, [address]);
  
  const { 
    data, 
    loading, 
    error, 
    loadData, 
    lastUpdated 
  } = useSmartCache(`balance-${address}`, fetchBalance, 60000); // 1分钟缓存
  
  const handleLoadData = (force = false) => {
    if (!address) return;
    loadData(force);
  };
  
  return (
    <div className="smart-cache-demo">
      <div className="input-group">
        <input
          type="text"
          value={address}
          onChange={(e) => setAddress(e.target.value)}
          placeholder="输入ETH地址"
        />
        <button onClick={() => handleLoadData(false)} disabled={!address || loading}>
          {loading ? '加载中...' : '加载数据'}
        </button>
        <button onClick={() => handleLoadData(true)} disabled={!address || loading}>
          强制刷新
        </button>
      </div>
      
      {error && <p className="error">错误: {error.message}</p>}
      
      {data && (
        <div className="data-display">
          <h5>缓存数据结果:</h5>
          <p><strong>地址:</strong> {data.address}</p>
          <p><strong>余额:</strong> {data.balance}</p>
          <p><strong>交易数:</strong> {data.txCount}</p>
          <p><strong>数据时间:</strong> {data.lastUpdated}</p>
          {lastUpdated > 0 && (
            <p className="cache-info">
              <small>缓存于 {new Date(lastUpdated).toLocaleTimeString()}</small>
            </p>
          )}
        </div>
      )}
    </div>
  );
};