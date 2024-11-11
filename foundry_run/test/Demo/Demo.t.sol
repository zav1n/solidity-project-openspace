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
        console.logBytes(abi.encode(address(0xD995005ae6753d821A85a53EE63661B03FE9bC0b), uint256(1000000 * 10 ** 18)));
        contractC.multicall(
            address(contractB),
            abi.encodeWithSignature("increase(uint256)", 10)
        );
        console.log(contractB.count());
    }
}
