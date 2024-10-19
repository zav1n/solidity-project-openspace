// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

// forge script script/DeployMyToken.s.sol --rpc-url ETH_RPC_URL --broadcast --verify -vvvv --account 8888



/**

forge verify-contract --chain sepolia --constructor-args 
"$(cast abi-encode 'constructor(string memory name_, string memory symbol_)' MyToken MTK)" 
0x1e5e67907f0c08871701e54099c1e68635f62b43 MyToken Start verifying contract `0x1e5e67907f0c08871701e54099c1e68635f62b43` 
deployed on sepolia   

 */

contract DeployMyToken is Script {
    function run() external {
        string memory name = "MyToken";
        string memory symbol = "MTK";

        vm.startBroadcast();
        new MyToken(name, symbol);
        vm.stopBroadcast();
    }
}