"use client";
import Image from "next/image";
import styles from "./page.module.css";
import {
  useAppKitAccount,
  useAppKit,
  useWalletInfo,
} from "@reown/appkit/react";
import { useDisconnect } from "wagmi";
import { useSignMessage } from "wagmi";

export default function Home() {
  const { address, caipAddress, status } = useAppKitAccount();
  const { open } = useAppKit();
  const { disconnect } = useDisconnect();
  const { walletInfo } = useWalletInfo();
  const { signMessage } = useSignMessage();

  const infos = [
    { label: "address", value: address },
    { label: "caipAddress", value: caipAddress },
    { label: "status", value: status },
  ];
  return (
    <div className={styles.page}>
      <main className={styles.main}>
        <div>
          <span style={{ fontSize: "2rem", fontWeight: "600" }}>
            React for Next.js / Appkit
          </span>
          <span style={{ marginLeft: "20px", fontSize: "13px" }}>
            Create by suzefeng
          </span>
        </div>
        <div className={styles.ctas}>
          {/* <a
            className={styles.primary}
            href="https://vercel.com/new?utm_source=create-next-app&utm_medium=appdir-template&utm_campaign=create-next-app"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Image
              className={styles.logo}
              src="https://nextjs.org/icons/vercel.svg"
              alt="Vercel logomark"
              width={20}
              height={20}
            />
            Deploy now
          </a> */}
          <a onClick={() => open({ view: "Account" })}>View Account</a>
          <a onClick={() => disconnect()}>Disconnect</a>
          <div>
            <img src={walletInfo?.icon} />
            {/* <div>{walletInfo?.name}</div> */}
          </div>
          <w3m-network-button />
          <w3m-button />
        </div>
        <ul>
          {infos.map((item, index) => {
            return (
              <li key={index}>
                {item.label}: {item.value}
              </li>
            );
          })}
        </ul>
        <button
          onClick={() => signMessage({ message: "hello world" })}
          className={styles.btn}
        >
          Sign message ( you will be sign message is hello world )
        </button>
      </main>
      <footer className={styles.footer}>
        <a
          href="https://nextjs.org/learn?utm_source=create-next-app&utm_medium=appdir-template&utm_campaign=create-next-app"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Image
            aria-hidden
            src="https://nextjs.org/icons/file.svg"
            alt="File icon"
            width={16}
            height={16}
          />
          Learn Next.js
        </a>
        <a
          href="https://vercel.com/templates?framework=next.js&utm_source=create-next-app&utm_medium=appdir-template&utm_campaign=create-next-app"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Image
            aria-hidden
            src="https://nextjs.org/icons/window.svg"
            alt="Window icon"
            width={16}
            height={16}
          />
          vercel
        </a>
        <a
          href="https://docs.reown.com/appkit/react/core/installation"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Image
            aria-hidden
            src="https://nextjs.org/icons/globe.svg"
            alt="Globe icon"
            width={16}
            height={16}
          />
          AppKit documentation
        </a>
      </footer>
    </div>
  );
}
