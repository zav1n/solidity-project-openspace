import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { useAccount, useConnect } from 'wagmi';
import { injected } from 'wagmi/connectors';

// 导入组件
const ENSResolver = React.lazy(() => import('./src/components/ENSResolver'));
const MultiChainWallet = React.lazy(() => import('./src/components/MultiChainWallet'));
const SignatureVerifier = React.lazy(() => import('./src/components/SignatureVerifier'));

const Home = () => {
  const { connectAsync, isPending } = useConnect();
  const { isConnected } = useAccount();

  const handleConnect = async () => {
    try {
      await connectAsync({ connector: injected() });
    } catch (error) {
      console.error('连接钱包失败:', error);
    }
  };

  return (
    <div>
      <h2>欢迎使用 Web3 应用</h2>
      <p>这是一个多功能的 Web3 应用程序，提供以下功能：</p>
      <ul>
        <li>ENS 域名解析</li>
        <li>多链钱包连接</li>
        <li>消息签名与验证</li>
      </ul>
      <p>请使用上方导航菜单访问各个功能页面。</p>
      
      {!isConnected && (
        <div style={{ marginTop: '20px' }}>
          <button 
            onClick={handleConnect} 
            disabled={isPending}
            style={{
              padding: '10px 20px',
              backgroundColor: '#0066cc',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer',
              fontSize: '16px'
            }}
          >
            {isPending ? '连接中...' : '连接钱包'}
          </button>
        </div>
      )}
    </div>
  );
};

const App = () => {
  const { address, isConnecting, isDisconnected } = useAccount();

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <Router>
        <header style={{ marginBottom: '20px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h1 style={{ margin: 0 }}>Web3 应用</h1>
            <div>
              {isConnecting && <div>连接中...</div>}
              {isDisconnected ? (
                <div>钱包未连接</div>
              ) : (
                <div>已连接: {address}</div>
              )}
            </div>
          </div>
          <nav style={{ marginTop: '15px' }}>
            <ul style={{ display: 'flex', listStyle: 'none', padding: 0, gap: '15px' }}>
              <li>
                <Link to="/" style={{ textDecoration: 'none', color: '#0066cc' }}>首页</Link>
              </li>
              <li>
                <Link to="/ens" style={{ textDecoration: 'none', color: '#0066cc' }}>ENS 解析</Link>
              </li>
              <li>
                <Link to="/wallet" style={{ textDecoration: 'none', color: '#0066cc' }}>多链钱包</Link>
              </li>
              <li>
                <Link to="/signature" style={{ textDecoration: 'none', color: '#0066cc' }}>签名验证</Link>
              </li>
            </ul>
          </nav>
        </header>
        <main style={{ padding: '20px', border: '1px solid #eee', borderRadius: '5px' }}>
          <React.Suspense fallback={<div>加载中...</div>}>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/ens" element={<ENSResolver initialValue="" />} />
              <Route path="/wallet" element={<MultiChainWallet />} />
              <Route path="/signature" element={<SignatureVerifier />} />
            </Routes>
          </React.Suspense>
        </main>
        <footer style={{ marginTop: '20px', textAlign: 'center', fontSize: '0.8rem', color: '#666' }}>
          <p>© 2025 Web3 应用 - 基于区块链技术</p>
        </footer>
      </Router>
    </div>
  );
};

export default App;
