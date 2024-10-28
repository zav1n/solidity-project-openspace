// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {IDAIPermit} from "../interfaces/IDAIPermit.sol";
import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";
import {SafeCast160} from "./SafeCast160.sol";

/**
  Permit2 from :
  https://github.com/Uniswap/permit2/blob/main/src/libraries/Permit2Lib.sol
 */

library Permit2Lib {
    using SafeCast160 for uint256;
    bytes32 internal constant DAI_DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;
    bytes32 internal constant WETH9_ADDRESS = 0x000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;

    IAllowanceTransfer internal constant PERMIT2 =
        IAllowanceTransfer(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));

    function transferFrom2(ERC20 token, address from, address to, uint256 amount) internal {
        bytes memory inputData = abi.encodeCall(ERC20.transferFrom, (from, to, amount));

        bool success;
        assembly {
            success :=
                and(
                    or(eq(mload(0), 1), iszero(returndatasize())),
                    call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 32)
                )
        }

        if (!success) PERMIT2.transferFrom(from, to, amount.toUint160(), address(token));
    }

    function permit2(
        ERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        bytes memory inputData = abi.encodeWithSelector(ERC20.DOMAIN_SEPARATOR.selector);

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        bytes32 domainSeparator; // If the call succeeded, we'll capture the return value here.

        assembly {
            if iszero(eq(and(token, 0xffffffffffffffffffffffffffffffffffffffff), WETH9_ADDRESS)) {
                success :=
                    and(
                        and(iszero(iszero(mload(0))), eq(returndatasize(), 32)),
                        staticcall(5000, token, add(inputData, 32), mload(inputData), 0, 32)
                    )

                domainSeparator := mload(0) 
            }
        }

        if (success) {
            inputData = domainSeparator == DAI_DOMAIN_SEPARATOR
                ? abi.encodeCall(IDAIPermit.permit, (owner, spender, token.nonces(owner), deadline, true, v, r, s))
                : abi.encodeCall(ERC20.permit, (owner, spender, amount, deadline, v, r, s));

            assembly {
                success := call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 0)
            }
        }

        if (!success) {
            simplePermit2(token, owner, spender, amount, deadline, v, r, s);
        }
    }

    function simplePermit2(
        ERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        (,, uint48 nonce) = PERMIT2.allowance(owner, address(token), spender);

        PERMIT2.permit(
            owner,
            IAllowanceTransfer.PermitSingle({
                details: IAllowanceTransfer.PermitDetails({
                    token: address(token),
                    amount: amount.toUint160(),
                    expiration: type(uint48).max,
                    nonce: nonce
                }),
                spender: spender,
                sigDeadline: deadline
            }),
            bytes.concat(r, s, bytes1(v))
        );
    }
}