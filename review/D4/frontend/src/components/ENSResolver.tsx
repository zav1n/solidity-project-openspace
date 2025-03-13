import { useState } from 'react';
import { useEnsAddress, useEnsName } from 'wagmi';

interface ENSResolverProps {
  initialValue: string;
  onResolve?: (resolved: { address?: string; name?: string }) => void;
}

function ENSResolver({ initialValue, onResolve }: ENSResolverProps) {
  const [input, setInput] = useState(initialValue);

  // ENS名称 -> 地址
  const { data: ensAddress, isPending: addressLoading } = useEnsAddress({
    name: input.toLowerCase(),
    enabled: input.endsWith('.eth'),
  });

  // 地址 -> ENS名称
  const { data: ensName, isPending: nameLoading } = useEnsName({
    address: input as `0x${string}`,
    enabled: input.startsWith('0x'),
  });

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setInput(value);
  };

  // 当解析完成时触发回调
  if (onResolve && (ensAddress || ensName)) {
    onResolve({
      address: ensAddress,
      name: ensName,
    });
  }

  return (
    <div className="ens-resolver">
      <input
        type="text"
        value={input}
        onChange={handleInputChange}
        placeholder="输入ENS域名或地址"
        className="ens-input"
      />
      <div className="ens-result">
        {addressLoading || nameLoading ? (
          <p>正在解析...</p>
        ) : ensAddress ? (
          <p>地址: {ensAddress}</p>
        ) : ensName ? (
          <p>ENS名称: {ensName}</p>
        ) : (
          input && <p>未找到对应的ENS记录</p>
        )}
      </div>
    </div>
  );
}

export default ENSResolver;
