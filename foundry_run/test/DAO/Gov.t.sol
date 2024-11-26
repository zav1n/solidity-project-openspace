// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@src/DAO/VotingToken.sol";
import "@src/DAO/Bank.sol";
import "@src/DAO/Gov.sol";

contract GovTest is Test {
    VotingToken public token;
    Bank public bank;
    Gov public gov;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        token = new VotingToken(1_000_000 ether);
        bank = new Bank();
        gov = new Gov(token, bank);

        // 将 Bank 管理员设置为 Gov 合约
        bank.setAdmin(address(gov));

        // 分配 Token
        token.transfer(alice, 100 ether);
        token.transfer(bob, 50 ether);
    }

    function testProposeAndVote() public {
        // Alice 提交提案
        vm.startPrank(alice);
        token.delegate(alice); // 为自己委托投票权
        uint256 proposalId = gov.propose(address(bank), 10 ether, "");
        vm.stopPrank();

        // 检查提案
        (, , , uint256 value, , , , , ,) = gov.proposals(proposalId);
        assertEq(value, 10 ether);

        // Bob 投票支持
        vm.startPrank(bob);
        token.delegate(bob);
        gov.vote(proposalId, true);
        vm.stopPrank();

        // 检查投票结果
        (, , , , , , uint256 forVotes, uint256 againstVotes, ,) = gov.proposals(proposalId);
        assertEq(forVotes, 50 ether);
        assertEq(againstVotes, 0 ether);
    }

    function testExecuteProposal() public {
        // 设置初始资金
        vm.deal(address(bank), 20 ether);

        // 提交提案
        vm.startPrank(alice);
        token.delegate(alice);
        uint256 proposalId = gov.propose(address(bank), 10 ether, "");
        gov.vote(proposalId, true);
        vm.stopPrank();

        // 矿工时间跳转，结束投票期
        vm.roll(block.number + 5761);

        // 执行提案
        gov.execute(proposalId);

        // 检查资金转移
        assertEq(address(bank).balance, 10 ether);
        assertEq(address(alice).balance, 10 ether);
    }
}