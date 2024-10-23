// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "../src/MyToken.sol";


/**
    forge 跑script脚本 目录 广播 校验 校验者帐户 帐户名称(之前提前设置好的,可以forge wallet list 查看)
    forge script script/DeployMyToken.s.sol --broadcast --verify --account 8888

    验证合约
    $ forge verify-contract 0x4E67Cc4f2bDF34ed0953ed712362fE6dD1c8f367  src/3_deploy/MyToken.sol:MyToken  --rpc-url https://1rpc.io/sepolia -e XSFRNUH7ZYKHRQSP9JRB6575N3HKW7F87V 
 */


contract DeploySZFToken is Script {
    function run() external {
        string memory name = "suzefeng";
        string memory symbol = "SZF";
        // 如果createSelectFork这个没有设置,则命令需要配置 --rpc-url
        vm.createSelectFork("sepolia");
        vm.startBroadcast();
        new MyToken(name, symbol);
        vm.stopBroadcast();
    }
}