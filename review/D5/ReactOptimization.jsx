// React性能优化示例代码
import React, { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { ethers } from 'ethers';

/**
 * @title 优化的Web3组件示例
 * @dev 演示React性能优化和Web3调用缓存
 */

// 模拟Web3提供者
const getProvider = () => {
  // 在实际应用中，这会是一个真实的以太坊提供者
  return new ethers.providers.JsonRpcProvider('https://mainnet.infura.io/v3/your-infura-key');
};

// 模拟合约ABI
const CONTRACT_ABI = [
  'function balanceOf(address owner) view returns (uint256)',
  'function transfer(address to, uint256 amount) returns (bool)',
  'event Transfer(address indexed from, address indexed to, uint256 value)'
];

// 模拟合约地址
const CONTRACT_ADDRESS = '0x1234567890123456789012345678901234567890';

/**
 * @dev 使用useMemo缓存合约实例
 */
function useContract(address, abi) {
  const provider = useMemo(() => getProvider(), []);
  
  // 使用useMemo缓存合约实例，避免重复创建
  const contract = useMemo(() => {
    if (!address || !abi || !provider) return null;
    return new ethers.Contract(address, abi, provider);
  }, [address, abi, provider]);
  
  return contract;
}

/**
 * @dev 使用useCallback优化事件处理函数
 */
function TransferForm({ onTransfer }) {
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('');
  
  // 使用useCallback优化事件处理函数，避免不必要的重新渲染
  const handleSubmit = useCallback((e) => {
    e.preventDefault();
    if (recipient && amount) {
      onTransfer(recipient, amount);
      setRecipient('');
      setAmount('');
    }
  }, [recipient, amount, onTransfer]);
  
  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label>接收地址：</label>
        <input 
          type="text" 
          value={recipient} 
          onChange={(e) => setRecipient(e.target.value)} 
          placeholder="0x..."
        />
      </div>
      <div>
        <label>金额：</label>
        <input 
          type="text" 
          value={amount} 
          onChange={(e) => setAmount(e.target.value)} 
          placeholder="1.0"
        />
      </div>
      <button type="submit">转账</button>
    </form>
  );
}

/**
 * @dev 使用React.memo优化组件渲染
 */
const TokenBalance = React.memo(({ address, balance }) => {
  return (
    <div>
      <h3>账户余额</h3>
      <p>地址: {address}</p>
      <p>余额: {balance} ETH</p>
    </div>
  );
});

/**
 * @dev 使用虚拟列表渲染大数据
 */
function VirtualizedTransactionList({ transactions }) {
  const listRef = useRef(null);
  const [visibleItems, setVisibleItems] = useState([]);
  const itemHeight = 50; // 每个列表项的高度
  
  // 计算可见区域内的列表项
  const calculateVisibleItems = useCallback(() => {
    if (!listRef.current) return;
    
    const container = listRef.current;
    const scrollTop = container.scrollTop;
    const containerHeight = container.clientHeight;
    
    const startIndex = Math.floor(scrollTop / itemHeight);
    const endIndex = Math.min(
      startIndex + Math.ceil(containerHeight / itemHeight) + 1,
      transactions.length
    );
    
    setVisibleItems(
      transactions.slice(startIndex, endIndex).map((tx, index) => ({
        ...tx,
        index: startIndex + index,
        top: (startIndex + index) * itemHeight
      }))
    );
  }, [transactions, itemHeight]);
  
  // 监听滚动事件
  useEffect(() => {
    const container = listRef.current;
    if (!container) return;
    
    calculateVisibleItems();
    container.addEventListener('scroll', calculateVisibleItems);
    
    return () => {
      container.removeEventListener('scroll', calculateVisibleItems);
    };
  }, [calculateVisibleItems]);
  
  // 总高度
  const totalHeight = transactions.length * itemHeight;
  
  return (
    <div>
      <h3>交易历史</h3>
      <div 
        ref={listRef}
        style={{ 
          height: '300px', 
          overflow: 'auto',
          position: 'relative'
        }}
      >
        <div style={{ height: `${totalHeight}px`, position: 'relative' }}>
          {visibleItems.map(item => (
            <div 
              key={item.id} 
              style={{
                position: 'absolute',
                top: `${item.top}px`,
                left: 0,
                right: 0,
                height: `${itemHeight}px`,
                padding: '10px',
                borderBottom: '1px solid #eee'
              }}
            >
              <div>交易ID: {item.id}</div>
              <div>金额: {item.amount} ETH</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

/**
 * @dev 主应用组件
 */
export default function OptimizedDApp() {
  const [account, setAccount] = useState(null);
  const [balance, setBalance] = useState('0');
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  
  // 使用自定义Hook获取合约实例
  const contract = useContract(CONTRACT_ADDRESS, CONTRACT_ABI);
  
  // 连接钱包
  const connectWallet = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      // 在实际应用中，这会使用window.ethereum请求账户
      const accounts = ['0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266']; // 模拟账户
      setAccount(accounts[0]);
      
      // 获取余额
      if (contract) {
        const balance = await contract.balanceOf(accounts[0]);
        setBalance(ethers.utils.formatEther(balance));
      }
      
      // 模拟交易历史
      const mockTransactions = Array.from({ length: 1000 }, (_, i) => ({
        id: `tx-${i}`,
        from: '0x1234...',
        to: '0x5678...',
        amount: (Math.random() * 10).toFixed(4)
      }));
      setTransactions(mockTransactions);
    } catch (err) {
      console.error('连接钱包失败:', err);
      setError('连接钱包失败，请重试');
    } finally {
      setLoading(false);
    }
  }, [contract]);
  
  // 执行转账
  const handleTransfer = useCallback(async (to, amount) => {
    if (!contract || !account) return;
    
    try {
      setLoading(true);
      setError(null);
      
      // 在实际应用中，这会是一个真实的转账交易
      console.log(`转账 ${amount} 代币到 ${to}`);
      
      // 模拟交易成功
      setTimeout(() => {
        // 更新交易历史
        setTransactions(prev => [
          {
            id: `tx-${Date.now()}`,
            from: account,
            to,
            amount
          },
          ...prev
        ]);
        
        // 更新余额（模拟）
        setBalance(prev => (parseFloat(prev) - parseFloat(amount)).toFixed(4));
        setLoading(false);
      }, 1000);
    } catch (err) {
      console.error('转账失败:', err);
      setError('转账失败，请重试');
      setLoading(false);
    }
  }, [contract, account]);
  
  // 监听Transfer事件
  useEffect(() => {
    if (!contract || !account) return;
    
    // 设置事件监听器
    const fromFilter = contract.filters.Transfer(account, null);
    const toFilter = contract.filters.Transfer(null, account);
    
    const handleTransferEvent = (from, to, value) => {
      console.log('Transfer event:', { from, to, value });
      
      // 更新余额
      contract.balanceOf(account).then(balance => {
        setBalance(ethers.utils.formatEther(balance));
      });
      
      // 更新交易历史
      const newTx = {
        id: `tx-${Date.now()}`,
        from,
        to,
        amount: ethers.utils.formatEther(value)
      };
      
      setTransactions(prev => [newTx, ...prev]);
    };
    
    // 添加事件监听器
    contract.on(fromFilter, handleTransferEvent);
    contract.on(toFilter, handleTransferEvent);
    
    // 清理函数
    return () => {
      contract.off(fromFilter, handleTransferEvent);
      contract.off(toFilter, handleTransferEvent);
    };
  }, [contract, account]);
  
  return (
    <div className="app">
      <h1>优化的DApp示例</h1>
      
      {!account ? (
        <button onClick={connectWallet} disabled={loading}>
          {loading ? '连接中...' : '连接钱包'}
        </button>
      ) : (
        <div>
          {/* 使用React.memo优化的组件 */}
          <TokenBalance address={account} balance={balance} />
          
          {/* 使用useCallback优化的表单组件 */}
          <TransferForm onTransfer={handleTransfer} />
          
          {/* 使用虚拟列表优化的大数据渲染 */}
          <VirtualizedTransactionList transactions={transactions} />
          
          {/* 加载状态和错误处理 */}
          {loading && <div className="loading">处理中...</div>}
          {error && <div className="error">{error}</div>}
        </div>
      )}
    </div>
  );
}