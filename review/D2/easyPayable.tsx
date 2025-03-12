import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';

const EasyPayable: React.FC = () => {
  const [account, setAccount] = useState<string>('');
  const [balance, setBalance] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');
  const [amount, setAmount] = useState<string>('');
  const [recipient, setRecipient] = useState<string>('');
  const [provider, setProvider] = useState<ethers.providers.Web3Provider | null>(null);

  useEffect(() => {
    if (window.ethereum) {
      const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
      setProvider(web3Provider);
    }
  }, []);

  const connectWallet = async () => {
    try {
      setLoading(true);
      setError('');
      
      if (!window.ethereum) {
        throw new Error('请安装MetaMask钱包');
      }

      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      });

      setAccount(accounts[0]);
      await updateBalance(accounts[0]);

      // 监听账户变更
      window.ethereum.on('accountsChanged', handleAccountsChanged);
      // 监听链变更
      window.ethereum.on('chainChanged', () => window.location.reload());

    } catch (err: any) {
      setError(err.message || '连接钱包失败');
    } finally {
      setLoading(false);
    }
  };

  const handleAccountsChanged = async (accounts: string[]) => {
    if (accounts.length === 0) {
      setAccount('');
      setBalance('');
    } else {
      setAccount(accounts[0]);
      await updateBalance(accounts[0]);
    }
  };

  const updateBalance = async (address: string) => {
    try {
      if (!provider) return;
      const balance = await provider.getBalance(address);
      setBalance(ethers.utils.formatEther(balance));
    } catch (err: any) {
      setError('获取余额失败');
    }
  };

  const sendTransaction = async () => {
    try {
      setLoading(true);
      setError('');

      if (!provider || !amount || !recipient) {
        throw new Error('请填写完整信息');
      }

      const signer = provider.getSigner();
      const tx = await signer.sendTransaction({
        to: recipient,
        value: ethers.utils.parseEther(amount)
      });

      await tx.wait();
      await updateBalance(account);
      setAmount('');
      setRecipient('');

    } catch (err: any) {
      setError(err.message || '转账失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-4">
      <h1 className="text-2xl font-bold mb-4">ETH转账</h1>
      
      {!account ? (
        <button
          onClick={connectWallet}
          disabled={loading}
          className="bg-blue-500 text-white px-4 py-2 rounded disabled:bg-gray-400"
        >
          {loading ? '连接中...' : '连接钱包'}
        </button>
      ) : (
        <div className="space-y-4">
          <div>
            <p>账户地址: {account}</p>
            <p>ETH余额: {balance}</p>
          </div>

          <div className="space-y-2">
            <input
              type="text"
              placeholder="接收地址"
              value={recipient}
              onChange={(e) => setRecipient(e.target.value)}
              className="w-full p-2 border rounded"
            />
            <input
              type="number"
              placeholder="转账金额 (ETH)"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="w-full p-2 border rounded"
            />
            <button
              onClick={sendTransaction}
              disabled={loading}
              className="w-full bg-green-500 text-white px-4 py-2 rounded disabled:bg-gray-400"
            >
              {loading ? '转账中...' : '发送ETH'}
            </button>
          </div>
        </div>
      )}

      {error && (
        <div className="mt-4 p-2 bg-red-100 text-red-600 rounded">
          {error}
        </div>
      )}
    </div>
  );
};

export default EasyPayable;