const ethers = require("ethers");
const fs = require("fs");

async function generateKeystoreFromPrivateKey(privateKey, password) {
  // 使用私钥创建一个钱包实例
  const wallet = new ethers.Wallet(privateKey);

  // 使用密码加密钱包，并生成 keystore 文件内容
  const keystore = await wallet.encrypt(password);

  // 将 keystore 内容保存到一个文件
  fs.writeFileSync("keystore.json", keystore);
  console.log("Keystore saved to keystore.json");
}

// 替换为你的私钥和密码
const privateKey =
  ""; // 替换为实际私钥
const password = ""; // 设定一个强密码

generateKeystoreFromPrivateKey(privateKey, password);
