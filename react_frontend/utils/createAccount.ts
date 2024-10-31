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

generateNewAddress(true);
