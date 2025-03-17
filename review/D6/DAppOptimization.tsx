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
  
  return (
    <div className="transaction-confirmation">
      <h4>交易状态</h4>
      {renderStatus()}
    </div>
  );
};

/**
 * 使用示例
 */
export const DAppOptimizationExample: React.FC = () => {
  const [currentTxHash, setCurrentTxHash] = useState<string | null>(null);
  
  // 模拟交易发送
  const handleSendTransaction = () => {
    // 这里通常会调用实际的合约方法
    // 示例: 设置一个模拟的交易哈希
    setCurrentTxHash('0x0000000000000000000000000000000000000000000000000000000000000000');
  };
  
  return (
    <div className="dapp-optimization-example">
      <h3>DApp优化示例</h3>
      
      <div className="section">
        <h4