import { ethers } from "ethers";

async function generateNewAddress(isloop = false) {
  function createWallet() {
    const wallet = ethers.Wallet.createRandom();
    const address = wallet.address;
    const privateKey = wallet.privateKey;
    if (address.endsWith("AAAAA")) {
      console.log("Generated Address:", address);
      console.log("Generated Private Key:", privateKey);
    }
  }
  if (isloop) {
    setInterval(createWallet, 0);
  } else {
    createWallet();
  }
}

// A B C D E F
async function creatWallet() {
  setInterval(() => {
    let wallet; // 钱包
    const regex = /^0xFF.FFFF$/; // 表达式
    let isValid = false;
    while (!isValid) {
      wallet = ethers.Wallet.createRandom(); // 随机生成钱包，安全
      isValid = regex.test(wallet.address); // 检验正则表达式
    }
    // 打印靓号地址与私钥
    console.log(`靓号地址：${wallet.address}`);
    console.log(`靓号私钥：${wallet.privateKey}`);
  }, 0);
}

creatWallet();
generateNewAddress(true);
