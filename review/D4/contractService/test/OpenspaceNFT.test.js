const { expect } = require("chai");
const { ethers } = require("hardhat");

// 辅助函数，用于部署合约
async function deployContract() {
  const OpenspaceNFT = await ethers.getContractFactory("OpenspaceNFT");
  const [owner, addr1, addr2] = await ethers.getSigners();
  const openspaceNFT = await OpenspaceNFT.deploy();
  await openspaceNFT.deployed();
  return { openspaceNFT, owner, addr1, addr2 };
}

describe("OpenspaceNFT", function () {
  let openspaceNFT;
  let owner;
  let addr1;
  let addr2;
  const mintPrice = ethers.utils.parseEther("0.01");

  beforeEach(async function () {
    // 使用辅助函数部署合约
    const result = await deployContract();
    openspaceNFT = result.openspaceNFT;
    owner = result.owner;
    addr1 = result.addr1;
    addr2 = result.addr2;
  });

  describe("部署", function () {
    it("应该设置正确的所有者", async function () {
      expect(await openspaceNFT.owner()).to.equal(owner.address);
    });

    it("应该设置正确的名称和符号", async function () {
      expect(await openspaceNFT.name()).to.equal("OpenspaceNFT");
      expect(await openspaceNFT.symbol()).to.equal("OSNFT");
    });

    it("应该设置正确的铸造价格", async function () {
      expect(await openspaceNFT.mintPrice()).to.equal(mintPrice);
    });
  });

  describe("铸造", function () {
    it("应该允许用户铸造NFT", async function () {
      await openspaceNFT.connect(addr1).mint({ value: mintPrice });
      expect(await openspaceNFT.balanceOf(addr1.address)).to.equal(1);
      expect(await openspaceNFT.ownerOf(1)).to.equal(addr1.address);
    });

    it("如果付款不足，应该拒绝铸造", async function () {
      await expect(
        openspaceNFT.connect(addr1).mint({ value: ethers.utils.parseEther("0.005") })
      ).to.be.revertedWith("Insufficient payment");
    });

    it("应该递增tokenId", async function () {
      await openspaceNFT.connect(addr1).mint({ value: mintPrice });
      await openspaceNFT.connect(addr2).mint({ value: mintPrice });
      
      expect(await openspaceNFT.ownerOf(1)).to.equal(addr1.address);
      expect(await openspaceNFT.ownerOf(2)).to.equal(addr2.address);
    });
  });

  describe("BaseURI", function () {
    it("所有者应该能够设置baseURI", async function () {
      const baseURI = "https://example.com/token/";
      await openspaceNFT.connect(owner).setBaseURI(baseURI);
      
      await openspaceNFT.connect(addr1).mint({ value: mintPrice });
      expect(await openspaceNFT.tokenURI(1)).to.equal(baseURI + "1");
    });

    it("非所有者不应该能够设置baseURI", async function () {
      await expect(
        openspaceNFT.connect(addr1).setBaseURI("https://example.com/token/")
      ).to.be.reverted;
    });
  });

  describe("提款", function () {
    it("所有者应该能够提取合约余额", async function () {
      // 先铸造一个NFT来获得一些ETH
      await openspaceNFT.connect(addr1).mint({ value: mintPrice });
      
      const initialBalance = await ethers.provider.getBalance(owner.address);
      
      // 提取资金
      await openspaceNFT.connect(owner).withdraw();
      
      // 检查所有者余额是否增加
      const finalBalance = await ethers.provider.getBalance(owner.address);
      expect(finalBalance.gt(initialBalance)).to.be.true;
      
      // 检查合约余额是否为0
      const contractBalance = await ethers.provider.getBalance(openspaceNFT.address);
      expect(contractBalance).to.equal(0);
    });

    it("非所有者不应该能够提取余额", async function () {
      await openspaceNFT.connect(addr1).mint({ value: mintPrice });
      await expect(openspaceNFT.connect(addr1).withdraw()).to.be.reverted;
    });
  });
});
