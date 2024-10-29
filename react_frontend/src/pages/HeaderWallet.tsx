// import React from "react";
import {
  useAppKitAccount,
  useWalletInfo
} from "@reown/appkit/react";

const HeaderWallet = () => {
  const { address: currentAddress } = useAppKitAccount();
  const { walletInfo } = useWalletInfo();

  return (
    <div style={{ 
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      minHeight: "100px"
    }}>
      <div>
        <img src={walletInfo?.icon} />
      </div>
      <w3m-network-button />
      <w3m-button />

      <div>{currentAddress}</div>
    </div>
  );
};

export default HeaderWallet;
