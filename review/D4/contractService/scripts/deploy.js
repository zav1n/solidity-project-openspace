const hre = require("hardhat");

async function main() {
  // 检查当前网络
  const network = hre.network.name;
  console.log(`部署到网络: ${network}`);
  
  // 获取合约工厂
  const OpenspaceNFT = await hre.ethers.getContractFactory("OpenspaceNFT");
  
  // 部署合约
  console.log("开始部署合约...");
  const openspaceNFT = await OpenspaceNFT.deploy();
  // 等待合约部署完成
  await openspaceNFT.waitForDeployment();
  
  // 获取合约地址
  const contractAddress = await openspaceNFT.getAddress();
  console.log("OpenspaceNFT 已部署到:", contractAddress);
  
  // 设置基础URI
  const setBaseURITx = await openspaceNFT.setBaseURI("https://openspace-nft-api.example.com/metadata/");
  await setBaseURITx.wait();
  console.log("BaseURI 已设置");
  
  // 自动更新contractService.ts中的合约地址
  const fs = require('fs');
  const path = require('path');
  const contractServicePath = path.join(__dirname, '../services/contractService.ts');
  
  // 读取文件内容
  let content = fs.readFileSync(contractServicePath, 'utf8');
  
  // 使用正则表达式替换CONTRACT_ADDRESS
  content = content.replace(
    /export const CONTRACT_ADDRESS = '.*?';/,
    `export const CONTRACT_ADDRESS = '${contractAddress}';`
  );
  
  // 写回文件
  fs.writeFileSync(contractServicePath, content);
  console.log("\n\ncontractService.ts中的CONTRACT_ADDRESS已更新为:");
  console.log(`${contractAddress}`);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
