import React, { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import { useWeb3React } from '@web3-react/core';

/**
 * 交易状态枚举
 */
enum TransactionStatus {
  NONE = 'NONE',
  PENDING = 'PENDING',
  MINING = 'MINING',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  REJECTED = 'REJECTED'
}

/**
 * 交易信息接口
 */
interface Transaction {
  hash: string;
  description: string;
  status: TransactionStatus;
  confirmations: number;
  receipt?: ethers.providers.TransactionReceipt;
  submittedAt: number;
  confirmedAt?: number;
  error?: Error;
}

/**
 * 交易管理器Hook
 * 用于管理和跟踪以太坊交易状态
 */
export function useTransactionManager() {
  const { library, chainId } = useWeb3React();
  const [transactions, setTransactions] = useState<Record<string, Transaction>>({});
  
  // 添加新交易
  const addTransaction = useCallback(
    (hash: string, description: string) => {
      const newTx: Transaction = {
        hash,
        description,
        status: TransactionStatus.PENDING,
        confirmations: 0,
        submittedAt: Date.now(),
      };
      
      setTransactions((prevTransactions) => ({
        ...prevTransactions,
        [hash]: newTx,
      }));
      
      return hash;
    },
    []
  );
  
  // 更新交易状态
  const updateTransaction = useCallback(
    (hash: string, updates: Partial<Transaction>) => {
      setTransactions((prevTransactions) => {
        if (!prevTransactions[hash]) return prevTransactions;
        
        return {
          ...prevTransactions,
          [hash]: {
            ...prevTransactions[hash],
            ...updates,
          },
        };
      });
    },
    []
  );
  
  // 监听交易状态变化
  useEffect(() => {
    if (!library || !chainId) return;
    
    // 获取所有待处理交易
    const pendingTxs = Object.values(transactions).filter(
      (tx) => tx.status === TransactionStatus.PENDING || tx.status === TransactionStatus.MINING
    );
    
    if (pendingTxs.length === 0) return;
    
    // 为每个待处理交易设置监听器
    const unsubscribe = pendingTxs.map((tx) => {
      const { hash } = tx;
      
      // 首先检查交易是否已经被挖出
      library.getTransactionReceipt(hash).then((receipt) => {
        if (receipt) {
          updateTransaction(hash, {
            status: receipt.status === 1 ? TransactionStatus.SUCCESS : TransactionStatus.FAILED,
            receipt,
            confirmations: 1,
            confirmedAt: Date.now(),
          });
        } else {
          // 如果尚未被挖出，设置监听器
          updateTransaction(hash, { status: TransactionStatus.MINING });
          
          // 监听交易确认
          const onConfirmation = (confirmations: number, receipt: ethers.providers.TransactionReceipt) => {
            updateTransaction(hash, {
              status: receipt.status === 1 ? TransactionStatus.SUCCESS : TransactionStatus.FAILED,
              receipt,
              confirmations,
              confirmedAt: receipt.status === 1 ? Date.now() : undefined,
            });
          };
          
          // 监听交易错误
          const onError = (error: Error) => {
            updateTransaction(hash, {
              status: TransactionStatus.FAILED,
              error,
            });
          };
          
          // 设置监听器
          return library.once(hash, (receipt) => {
            onConfirmation(1, receipt);
          });
        }
      }).catch(console.error);
    });
    
    // 清理函数
    return () => {
      unsubscribe.forEach((unsub) => {
        if (typeof unsub === 'function') unsub();
      });
    };
  }, [chainId, library, transactions, updateTransaction]);
  
  // 发送交易并跟踪状态
  const sendTransaction = useCallback(
    async (transactionPromise: Promise<ethers.providers.TransactionResponse>, description: string) => {
      try {
        const tx = await transactionPromise;
        const hash = addTransaction(tx.hash, description);
        
        return {
          hash,
          wait: async (confirmations = 1) => {
            const receipt = await tx.wait(confirmations);
            return receipt;
          },
        };
      } catch (error: any) {
        // 处理用户拒绝交易的情况
        if (error.code === 4001) {
          throw new Error('Transaction rejected by user');
        }
        throw error;
      }
    },
    [addTransaction]
  );
  
  // 重试失败的交易
  const retryTransaction = useCallback(
    async (hash: string, newTransactionPromise: Promise<ethers.providers.TransactionResponse>) => {
      const tx = transactions[hash];
      if (!tx) return null;
      
      try {
        // 删除旧交易记录
        setTransactions((prevTransactions) => {
          const newTransactions = { ...prevTransactions };
          delete newTransactions[hash];
          return newTransactions;
        });
        
        // 发送新交易
        const newTx = await newTransactionPromise;
        const newHash = addTransaction(newTx.hash, tx.description);
        
        return {
          hash: newHash,
          wait: async (confirmations = 1) => {
            const receipt = await newTx.wait(confirmations);
            return receipt;
          },
        };
      } catch (error: any) {
        if (error.code === 4001) {
          throw new Error('Transaction retry rejected by user');
        }
        throw error;
      }
    },
    [transactions, addTransaction]
  );
  
  return {
    transactions,
    sendTransaction,
    retryTransaction,
  };
}

/**
 * 交易状态组件示例
 */
interface TransactionStatusProps {
  hash: string;
  onConfirmed?: (receipt: ethers.providers.TransactionReceipt) => void;
}

export const TransactionStatus: React.FC<TransactionStatusProps> = ({ hash, onConfirmed }) => {
  const { transactions } = useTransactionManager();
  const tx = transactions[hash];
  
  useEffect(() => {
    if (tx?.status === TransactionStatus.SUCCESS && tx.receipt && onConfirmed) {
      onConfirmed(tx.receipt);
    }
  }, [tx, onConfirmed]);
  
  if (!tx) return <div>交易未找到</div>;
  
  return (
    <div className="transaction-status">
      <h4>{tx.description}</h4>
      <div className="status">
        {tx.status === TransactionStatus.PENDING && (
          <>
            <div className="spinner"></div>
            <span>等待钱包确认...</span>
          </>
        )}
        
        {tx.status === TransactionStatus.MINING && (
          <>
            <div className="spinner"></div>
            <span>交易确认中... ({tx.confirmations} 确认)</span>
          </>
        )}
        
        {tx.status === TransactionStatus.SUCCESS && (
          <>
            <div className="success-icon">✓</div>
            <span>交易成功!</span>
            <a 
              href={`https://etherscan.io/tx/${tx.hash}`} 
              target="_blank" 
              rel="noopener noreferrer"
            >
              在区块浏览器中查看
            </a>
          </>
        )}
        
        {tx.status === TransactionStatus.FAILED && (
          <>
            <div className="error-icon">✗</div>
            <span>交易失败: {tx.error?.message || '未知错误'}</span>
          </>
        )}
        
        {tx.status === TransactionStatus.REJECTED && (
          <>
            <div className="error-icon">✗</div>
            <span>交易被拒绝</span>
          </>
        )}
      </div>
    </div>
  );
};

/**
 * 使用示例
 */
export const TransactionExample: React.FC = () => {
  const { sendTransaction } = useTransactionManager();
  const [currentTx, setCurrentTx] = useState<string | null>(null);
  const { library, account } = useWeb3React();
  
  const handleSendTransaction = async () => {
    if (!library || !account) return;
    
    try {
      // 创建一个简单的ETH转账交易
      const tx = await sendTransaction(
        library.getSigner().sendTransaction({
          to: ethers.constants.AddressZero, // 示例地址
          value: ethers.utils.parseEther('0.001'),
        }),
        '发送 0.001 ETH'
      );
      
      setCurrentTx(tx.hash);
    } catch (error) {
      console.error('Transaction error:', error);
    }
  };
  
  const handleConfirmed = (receipt: ethers.providers.TransactionReceipt) => {
    console.log('Transaction confirmed!', receipt);
    // 在这里处理交易确认后的逻辑
  };
  
  return (
    <div>
      <h3>交易示例</h3>
      <button onClick={handleSendTransaction} disabled={!account}>
        发送测试交易
      </button>
      
      {currentTx && <TransactionStatus hash={currentTx} onConfirmed={handleConfirmed} />}
    </div>
  );
};