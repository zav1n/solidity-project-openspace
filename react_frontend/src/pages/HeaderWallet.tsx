// import React from "react";
import {
  useAppKitAccount,
  useAppKit,
  useWalletInfo
} from "@reown/appkit/react";
import { useDisconnect } from "wagmi";
import "../App.css"

const HeaderWallet = () => {
  const { address: currentAddress, caipAddress, status } = useAppKitAccount();
  const { open } = useAppKit();
  const { disconnect } = useDisconnect();
  const { walletInfo } = useWalletInfo();

  const infos = [
    { label: "address", value: currentAddress },
    { label: "caipAddress", value: caipAddress },
    { label: "status", value: status }
  ];

  return (
    <div style={{ display: "flex", alignItems: "center" }}>
      <button onClick={() => open({ view: "Account" })}>View Account</button>
      <button onClick={() => disconnect()}>Disconnect</button>
      <div>
        <img src={walletInfo?.icon} />
        {/* <div>{walletInfo?.name}</div> */}
      </div>
      <w3m-network-button />
      <w3m-button />
      <ul>
        {infos.map((item, index) => {
          return (
            <li key={index}>
              {item.label}: {item.value}
            </li>
          );
        })}
      </ul>
      {/* <button
        onClick={() => signMessage({ message: "hello world" })}
        className={"btn"}
      >
        Sign message ( you will be sign message is hello world )
      </button> */}
    </div>
  );
};

export default HeaderWallet;
