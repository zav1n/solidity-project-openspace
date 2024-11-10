// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {B, C} from "./Demo.sol";


contract DemoTest is Test {
    B contractB;
    C contractC;
    function setUp() public {
        contractB = new B();
        contractC = new C();
    }

    function test_delegatecallfn() public {
        contractC.delegatecallfn(address(contractB));
    }
    function test_multicall() public {
        contractC.multicall(
            address(contractB),
            abi.encodeWithSignature("increase(uint256)", 10)
        );
        console.log(contractB.count());
    }
}
