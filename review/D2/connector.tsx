import React, { useState, useEffect } from 'react';
import { ConnectorProvider } from './ConnectorProvider';

const App: React.FC = () => {
  const [connector] = useState(() => new ConnectorProvider());
  const [currentAccount, setCurrentAccount] = useState<string | null>(null);
  const [ethAddress, setEthAddress] = useState('');
  const [ethBalance, setEthBalance] = useState('-');
  const [tokenAddress, setTokenAddress] = useState('');
  const [userAddress, setUserAddress] = useState('');
  const [tokenBalance, setTokenBalance] = useState({ balance: '-', symbol: '' });

  useEffect(() => {
    // 监听账户变更
    connector.onAccountsChanged((accounts: string[]) => {
      if (accounts.length > 0) {
        setCurrentAccount(accounts[0]);
      } else {
        setCurrentAccount(null);
      }
    });

    // 监听网络变更
    connector.onChainChanged((chainId: string) => {
      alert(`网络已切换：${chainId}`);
    });

    return () => {
      connector.removeListeners();
    };
  }, [connector]);

  const handleConnect = async () => {
    try {
      const account = await connector.connect();
      setCurrentAccount(account);
    } catch (error: any) {
      alert('连接失败：' + error.message);
    }
  };

  const handleGetEthBalance = async () => {
    if (!ethAddress) {
      alert('请输入要查询的地址');
      return;
    }
    try {
      const balance = await connector.getETHBalance(ethAddress);
      setEthBalance(`${balance} ETH`);
    } catch (error: any) {
      alert('查询失败：' + error.message);
    }
  };

  const handleGetTokenBalance = async () => {
    if (!tokenAddress || !userAddress) {
      alert('请输入代币地址和用户地址');
      return;
    }
    try {
      const result = await connector.getERC20Balance(tokenAddress, userAddress);
      setTokenBalance(result);
    } catch (error: any) {
      alert('查询失败：' + error.message);
    }
  };

  return (
    <div style={{
      fontFamily: 'Arial, sans-serif',
      maxWidth: '800px',
      margin: '0 auto',
      padding: '20px'
    }}>
      <h1>MetaMask连接测试</h1>
      
      <div className="container">
        <button onClick={handleConnect}>连接MetaMask</button>
        <div className="result">
          当前账户：{currentAccount || '未连接'}
        </div>
      </div>

      <div className="container">
        <h2>ETH余额查询</h2>
        <input
          type="text"
          value={ethAddress}
          onChange={(e) => setEthAddress(e.target.value)}
          placeholder="输入要查询的ETH地址"
        />
        <button onClick={handleGetEthBalance}>查询ETH余额</button>
        <div className="result">ETH余额：{ethBalance}</div>
      </div>

      <div className="container">
        <h2>ERC20代币余额查询</h2>
        <input
          type="text"
          value={tokenAddress}
          onChange={(e) => setTokenAddress(e.target.value)}
          placeholder="输入代币合约地址"
        />
        <input
          type="text"
          value={userAddress}
          onChange={(e) => setUserAddress(e.target.value)}
          placeholder="输入要查询的用户地址"
        />
        <button onClick={handleGetTokenBalance}>查询代币余额</button>
        <div className="result">
          代币余额：{tokenBalance.balance} {tokenBalance.symbol}
        </div>
      </div>

      <style>{`
        .container {
          background-color: #f5f5f5;
          padding: 20px;
          border-radius: 8px;
          margin-top: 20px;
        }
        button {
          background-color: #4CAF50;
          color: white;
          padding: 10px 20px;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          margin: 5px;
        }
        button:hover {
          background-color: #45a049;
        }
        .result {
          margin-top: 10px;
          padding: 10px;
          border: 1px solid #ddd;
          border-radius: 4px;
        }
        input {
          padding: 8px;
          margin: 5px;
          border: 1px solid #ddd;
          border-radius: 4px;
          width: 300px;
        }
      `}</style>
    </div>
  );
};

export default App;