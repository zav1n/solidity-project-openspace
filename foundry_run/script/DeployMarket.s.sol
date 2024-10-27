// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "@src/Signature/TokenPermitERC20.sol";
import "@src/Signature/NFTMarketplace.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";


// forge script script/DeployBank.s.sol --broadcast --verify --account 8888


contract DeployBank is Script {
    function run() external {
        vm.createSelectFork("sepolia");
        vm.startBroadcast();
          TokenPermit token = new TokenPermit("test", "TTT", (10 ** 10) * 10 ** 18);
          DecertERC721 nft721 = new DecertERC721("SeafoodMarket", "SFM");
          new NFTMarketplace(address(token), address(nft721), "testNFT");
        vm.stopBroadcast();
    }
}