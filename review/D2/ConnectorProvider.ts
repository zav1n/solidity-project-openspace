import { ethers } from 'ethers';

// ERC20代币的基础ABI
const ERC20_ABI = [
  'function balanceOf(address owner) view returns (uint256)',
  'function decimals() view returns (uint8)',
  'function symbol() view returns (string)'
];

export class ConnectorProvider {
  private provider: ethers.providers.Web3Provider | null = null;
  private signer: ethers.Signer | null = null;

  // 初始化provider
  async init() {
    if (typeof window.ethereum === 'undefined') {
      throw new Error('请安装MetaMask钱包');
    }
    this.provider = new ethers.providers.Web3Provider(window.ethereum);
  }

  // 连接钱包
  async connect() {
    if (!this.provider) {
      await this.init();
    }
    try {
      await this.provider!.send('eth_requestAccounts', []);
      this.signer = this.provider!.getSigner();
      return await this.signer.getAddress();
    } catch (error) {
      console.error('连接钱包失败:', error);
      throw error;
    }
  }

  // 获取ETH余额
  async getETHBalance(address: string) {
    if (!this.provider) throw new Error('Provider未初始化');
    try {
      const balance = await this.provider.getBalance(address);
      return ethers.utils.formatEther(balance);
    } catch (error) {
      console.error('获取ETH余额失败:', error);
      throw error;
    }
  }

  // 获取ERC20代币余额
  async getERC20Balance(tokenAddress: string, userAddress: string) {
    if (!this.provider) throw new Error('Provider未初始化');
    try {
      const contract = new ethers.Contract(tokenAddress, ERC20_ABI, this.provider);
      const [balance, decimals, symbol] = await Promise.all([
        contract.balanceOf(userAddress),
        contract.decimals(),
        contract.symbol()
      ]);
      const formattedBalance = ethers.utils.formatUnits(balance, decimals);
      return { balance: formattedBalance, symbol };
    } catch (error) {
      console.error('获取代币余额失败:', error);
      throw error;
    }
  }

  // 监听账户变更
  onAccountsChanged(callback: (accounts: string[]) => void) {
    if (typeof window.ethereum === 'undefined') return;
    window.ethereum.on('accountsChanged', callback);
  }

  // 监听网络变更
  onChainChanged(callback: (chainId: string) => void) {
    if (typeof window.ethereum === 'undefined') return;
    window.ethereum.on('chainChanged', callback);
  }

  // 移除事件监听
  removeListeners() {
    if (typeof window.ethereum === 'undefined') return;
    window.ethereum.removeListener('accountsChanged', () => {});
    window.ethereum.removeListener('chainChanged', () => {});
  }

  // 获取当前网络
  async getNetwork() {
    if (!this.provider) throw new Error('Provider未初始化');
    return await this.provider.getNetwork();
  }
}

// 为window对象添加ethereum类型
declare global {
  interface Window {
    ethereum: any;
  }
}