// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DecertERC721.sol";


contract DeployBank is Script {
    function run() external {
        // 如果createSelectFork这个没有设置,则命令需要配置 --rpc-url
        vm.createSelectFork("sepolia");
        vm.startBroadcast();
        new DecertERC721("NFTERC721","NTE");
        vm.stopBroadcast();
    }
}