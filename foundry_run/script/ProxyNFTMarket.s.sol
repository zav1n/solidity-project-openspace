// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@src/Signature/TokenPermitERC20.sol";
import "@src/Signature/NFTMarketplaceV2.sol";
import { DecertERC721 } from "@src/DecertERC721.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// forge script script/ProxyNFTMarket.s.sol --broadcast --verify --account 8888
contract DeploySZFToken is Script {
    function run() external returns(address){
        // 如果createSelectFork这个没有设置,则命令需要配置 --rpc-url
        address suzefeng = address(0xeEE4739AD49c232Ef2Bb968fC2346Edbe03c8888);
        vm.createSelectFork("sepolia");
        vm.startBroadcast();
          TokenPermit token = new TokenPermit("test", "TTT", (10 ** 10) * 10 ** 18);
          DecertERC721 nft721 = new DecertERC721("SeafoodMarket", "SFM");
          NFTMarketplaceV2 impl = new NFTMarketplaceV2();
          
          ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(impl.initialize, (address(token), address(nft721), suzefeng))
          );
          NFTMarketplaceV2 nftMarket = NFTMarketplaceV2(address(proxy));
        vm.stopBroadcast();
        return address(nftMarket);
    }
}