// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Demo.sol";


contract DemoTest is Test {
    Demo p;
    function setUp() public {
        p = new Demo();
        (, uint256 value) = p.information();
        assertEq(value, 100);
    }
    function test() public {}
}
