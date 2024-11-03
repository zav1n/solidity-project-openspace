// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Demo.sol";


contract DemoTest is Test {
    Demo demo;
    function setUp() public {
        demo = new Demo();
    }
    function test() public {
        demo.day(block.timestamp + 18 days, 1 ether);
    }
}
