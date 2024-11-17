// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@src/W6D5_flashboot/OpenspaceNFT.sol";

// forge script script/OpenspaceNFT.s.sol --broadcast --verify --account signer2

contract DeployOpenspaceNFT is Script {
    function run() external {
        vm.createSelectFork("sepolia");
        vm.startBroadcast();
          new OpenspaceNFT();
        vm.stopBroadcast();
    }
}