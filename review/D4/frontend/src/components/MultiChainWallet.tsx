import { useAccount, useConfig, useConnect } from 'wagmi';
import { injected } from 'wagmi/connectors';
import React from 'react';

function MultiChainWallet() {
  const config = useConfig();
  const { chains } = config;
  const { chain, address, isConnected } = useAccount();
  const { connectAsync } = useConnect();

  const handleConnect = async () => {
    try {
      await connectAsync({ connector: injected() });
    } catch (error) {
      console.error('连接钱包失败:', error);
    }
  };

  const handleSwitchNetwork = async (chainId: number) => {
    // 在 wagmi v2 中，需要使用不同的方式切换网络
    // 这里简化处理，实际应用中可能需要更复杂的逻辑
    if (window.ethereum) {
      try {
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: `0x${chainId.toString(16)}` }],
        });
      } catch (error) {
        console.error('切换网络失败:', error);
      }
    }
  };

  return (
    <div className="wallet-container">
      {isConnected ? (
        <div>
          <p>当前连接地址: {address}</p>
          <p>当前网络: {chain?.name}</p>
          <div className="network-list">
            {chains.map((x) => (
              <button
                key={x.id}
                onClick={() => handleSwitchNetwork(x.id)}
                disabled={x.id === chain?.id}
              >
                切换到 {x.name}
              </button>
            ))}
          </div>
        </div>
      ) : (
        <button onClick={handleConnect}>连接钱包</button>
      )}
    </div>
  );
}

export default MultiChainWallet;
