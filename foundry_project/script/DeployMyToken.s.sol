// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "../src/MyToken.sol";


/**
    forge 跑script脚本 目录 广播 校验 校验者帐户 帐户名称(之前提前设置好的,可以forge wallet list 查看)
    forge script script/DeployMyToken.s.sol --broadcast --verify --account 8888


 */


contract DeployMyToken is Script {
    function run() external {
        string memory name = "MyToken";
        string memory symbol = "MTK";
        // 如果createSelectFork这个没有设置,则命令需要配置 --rpc-url
        vm.createSelectFork("sepolia");
        vm.startBroadcast();
        new MyToken(name, symbol);
        vm.stopBroadcast();
    }
}