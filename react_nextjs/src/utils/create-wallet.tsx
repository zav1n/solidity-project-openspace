import { ethers } from 'ethers';
// 生成特定后缀的私钥和地址，并指定后缀长度
async function generateVanityAddress(targetSuffix: string, suffixLength: number) {
    if (targetSuffix.length !== suffixLength) {
        throw new Error("目标后缀长度与指定长度不匹配");
    }

    let wallet, address;
    const suffix = targetSuffix.toLowerCase();

    // 继续生成直到地址的后几位符合条件
    do {
        wallet = ethers.Wallet.createRandom();
        address = wallet.address.toLowerCase();
    } while (!address.endsWith(suffix));

    console.log("私钥:", wallet.privateKey);
    console.log("地址:", address);
    return wallet;
}

// 使用例子: 生成地址以 "1234" 结尾，指定长度为 4
generateVanityAddress("1234", 4);