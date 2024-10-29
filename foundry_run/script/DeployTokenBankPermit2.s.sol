// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@src/Permit2/TokenBankPermit2.sol";
import "forge-std/Script.sol";

contract DeployTokenBankPermit2 is Script {

    function setUp() public {}

    function run() public {
        vm.createSelectFork("sepolia");
        vm.startBroadcast();
        address permit2Contract = 0xa56f03C8B459a479Aea272CB7C1B454Fc3827BFb;
        new TokenBank(permit2Contract);

        vm.stopBroadcast();
    }
}
