// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { TokenBank } from "../../src/Signature/TokenBank.sol";
import { TokenPermit } from "@src/Signature/TokenPermitERC20.sol";

contract TokenBankTest is Test {
    TokenBank public bank;
    TokenPermit public token;
    address public owner;
    uint256 private ownerPrivateKey;

    function setUp() public {
      ownerPrivateKey = uint256(keccak256(abi.encodePacked("owner")));
      owner = vm.addr(ownerPrivateKey);

      token = new TokenPermit("test", "TTT", 100000 * 10 ** 18);

      bank = new TokenBank();

      token.mint(owner, 1000 * 10 ** token.decimals());
    }

    function testDeposit() public {
      uint256 amount = 100 * 10 ** token.decimals();

      // 先授权给TokenBank合约
      vm.prank(owner);
      token.approve(address(bank), amount);

      // 调用TokenBank的deposit函数
      vm.prank(owner);
      bank.deposit(token, amount);

      // 检查TokenBank合约的余额和用户的存款
      assertEq(token.balanceOf(address(bank)), amount);
      assertEq(bank.getBalance(token, owner), amount);
    }

    function test_permitDeposit() public {
      uint256 amount = 100 * 10 ** 18;
      uint256 nonce = token.nonces(owner);
      uint256 deadline = block.timestamp + 1 days;


      // 我们所说的EIP2612标准 满足keccak256(abi.encodePacked("lx19lx01", domainSeparator, hashstruct)
      // domainSeparator = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
      bytes32 domainSeparator = token.getDomainSeparator();
      bytes32 hashStruct = keccak256(abi.encode(
            token.getPermitTypehash(),
            owner,
            address(bank),
            amount,
            nonce,
            deadline
          ));
      
      // 再拿私钥和hash获取v，r，s
      bytes32 permitHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashStruct));

      (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, permitHash);

      address signer = ecrecover(permitHash, v, r, s);

      assertEq(owner, signer);

      vm.prank(owner);
      bank.permitDeposit(token, owner, amount, deadline, v, r, s);
    }

}
