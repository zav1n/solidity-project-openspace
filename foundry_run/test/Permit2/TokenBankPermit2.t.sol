// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../TestUtils.sol";

import "@src/DecertERC20.sol";
import "permit2/src/Permit2.sol";
import "@src/Permit2/TokenBankPermit2.sol";
import {IPermit2, IAllowanceTransfer, ISignatureTransfer } from "permit2/src/interfaces/IPermit2.sol";



contract TokenBankPermit2 is Test, TestUtils {
    // bytes32 constant SALT = bytes32(uint256(0x0000000000000000000000000000000000000000d3af2663ff51c10215000000));
    DecertERC20 token;
    Permit2 permit2;
    TokenBank tokenBank;

    bytes32 constant TOKEN_PERMISSIONS_TYPEHASH =
        keccak256("TokenPermissions(address token,uint256 amount)");
    bytes32 constant PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );
    bytes32 constant PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    uint256 private alicePrivateKey;
    address public alice;
    
    function setUp() public {
        token = new DecertERC20("tokenPermit2", "TKP");
        // permit2 = new Permit2{salt: SALT}();

        permit2 = new Permit2();
        tokenBank = new TokenBank(address(permit2));

        alicePrivateKey = uint256(keccak256(abi.encodePacked("alice")));
        alice = vm.addr(alicePrivateKey);
        token.transfer(alice, 10000 ether);

        vm.prank(alice);
        token.approve(address(permit2), type(uint256).max);
    }


    function test_depositWithPermit2() public {
        uint256 amount = 1000 ether;

        IPermit2.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({
                token: address(token),
                amount: amount
            }),
            nonce: _randomUint256(),
            deadline: block.timestamp
        });

        bytes memory sig = _signPermit(permit, address(tokenBank), alicePrivateKey);
        vm.prank(alice);
        tokenBank.depositWithPermit2(
            IERC20(address(token)),
            amount,
            permit.nonce,
            permit.deadline,
            sig
        );
        // assertEq(tokenBank.balances(token, alice), amount);
        // assertEq(token.balanceOf(address(tokenBank)), amount);
        // assertEq(token.balanceOf(alice), 0);
    }

    function _signPermit(
        IPermit2.PermitTransferFrom memory permit,
        address spender,
        uint256 signerKey
    )
        internal
        view
        returns (bytes memory sig)
    {
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerKey, _getEIP712Hash(permit, spender));
        return abi.encodePacked(r, s, v);
    }

    function _getEIP712Hash(IPermit2.PermitTransferFrom memory permit, address spender)
        internal
        view
        returns (bytes32 h)
    {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            permit2.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                PERMIT_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encode(
                    TOKEN_PERMISSIONS_TYPEHASH,
                    permit.permitted.token,
                    permit.permitted.amount
                )),
                spender,
                permit.nonce,
                permit.deadline
            ))
        ));
    }
}
