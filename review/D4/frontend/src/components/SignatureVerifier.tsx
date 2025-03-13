import { useState } from 'react';
import { useSignMessage, useAccount } from 'wagmi';
import * as ethers from 'ethers';

function SignatureVerifier() {
  const [message, setMessage] = useState('');
  const [signature, setSignature] = useState('');
  const [verified, setVerified] = useState<boolean | null>(null);
  const { address } = useAccount();

  const { signMessageAsync } = useSignMessage();

  const handleSignMessage = async () => {
    if (!message) return;
    try {
      const sig = await signMessageAsync({ message });
      setSignature(sig);
      verifySignature(message, sig);
    } catch (err) {
      console.error('签名消息失败:', err);
    }
  };

  const verifySignature = async (originalMessage: string, sig: string) => {
    try {
      const recoveredAddress = await ethers.utils.verifyMessage(originalMessage, sig);
      setVerified(recoveredAddress.toLowerCase() === address?.toLowerCase());
    } catch (err) {
      console.error('验证签名失败:', err);
      setVerified(false);
    }
  };

  return (
    <div className="signature-verifier">
      <div className="message-input">
        <input
          type="text"
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="输入要签名的消息"
        />
        <button onClick={handleSignMessage} disabled={!message}>
          签名消息
        </button>
      </div>

      {signature && (
        <div className="signature-result">
          <p>签名结果:</p>
          <textarea readOnly value={signature} />
          <p>
            验证结果:{' '}
            {verified === null
              ? '等待验证...'
              : verified
              ? '✅ 签名有效'
              : '❌ 签名无效'}
          </p>
        </div>
      )}
    </div>
  );
}

export default SignatureVerifier;
