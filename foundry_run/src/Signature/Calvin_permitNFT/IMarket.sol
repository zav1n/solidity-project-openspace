// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarket {
    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    struct WhiteList {
        address[] whiteList;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    function transferWithPermit(
        Permit calldata data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}