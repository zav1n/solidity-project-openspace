// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "@src/Permit2/TokenBankPermit2.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";


/**
  $ forge test --fork-url sepolia ./test/Permit2/TokenBankPermit2.t.sol

  abount [sepolia] option, you need add rpc-url in foundry.toml for example;
  [rpc_endpoints]
    sepolia = "https://xxxx"
 */
contract TokenBankTest is Test {
    TokenBank public bank;
    address constant permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address alice;
    uint256 alicePK;
    MockERC20 kk;

    function setUp() public {
        (alice, alicePK) = makeAddrAndKey("alice");

        require(block.chainid == 11155111, "Only support sepolia");
        bank = new TokenBank(permit2); // sepolia

        alice = makeAddr("alice");
        kk = deployMockERC20("TestToken", "KK", 18);
        deal(address(kk), alice, 1e10 * 1e18);
        vm.prank(alice);
        kk.approve(permit2, type(uint256).max);
    }

    function testDeposit() public {
        /// 2. sign permit
        ReqParams memory params = signToPermit2(alicePK, address(kk), 100, IPermit2(permit2).DOMAIN_SEPARATOR());
        // 3. deposit
        vm.prank(alice);
        bank.depositWithPermit2(params.token, params.amount, params.permit, params.signature);
        assertEq(bank.balances(alice, address(kk)), 100);

        // 4. withdraw
        vm.prank(alice);
        bank.withdraw(IERC20(address(kk)), 100);
    }

    struct ReqParams {
        IERC20 token;
        uint256 amount;
        PermitTransferFrom permit;
        bytes signature;
    }

    function signToPermit2(uint256 privateKey, address token, uint256 amount, bytes32 domainSeparator)
        private
        returns (ReqParams memory)
    {
        PermitTransferFrom memory permit = PermitTransferFrom({
            permitted: TokenPermissions({token: token, amount: amount}),
            nonce: block.timestamp,
            deadline: block.timestamp + 1 hours
        });

        // hashStruct(TokenPermissions)
        bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted));
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        _PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissions, address(bank), permit.nonce, permit.deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));
        return ReqParams({token: IERC20(token), amount: amount, permit: permit, signature: signature});
    }

    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );
    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    function getPermitTransferSignature(PermitTransferFrom memory permit, uint256 privateKey, bytes32 domainSeparator)
        internal
        view
        returns (bytes memory sig)
    {
        // hashStruct(TokenPermissions)
        bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted));
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        _PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissions, address(this), permit.nonce, permit.deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }
}