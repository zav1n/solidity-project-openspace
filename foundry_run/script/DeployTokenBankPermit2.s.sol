// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@src/Permit2/TokenBankPermit2.sol";


contract DeployTokenBankPermit2 is Script {

    function setUp() public {}

    function run() public {
        vm.startBroadcast("sepolia");

        new TokenBank();

        vm.stopBroadcast();
    }
}
