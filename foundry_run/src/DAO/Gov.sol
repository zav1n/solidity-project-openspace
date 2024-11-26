// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VotingToken.sol";
import "./Bank.sol";

contract Gov {
    struct Proposal {
        uint256 id;
        address proposer;
        address target;
        uint256 value;
        bytes data;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    VotingToken public token;
    Bank public bank;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 id, address proposer, address target, uint256 value, bytes data);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 id);

    constructor(VotingToken _token, Bank _bank) {
        token = _token;
        bank = _bank;
    }

    function propose(
        address target,
        uint256 value,
        bytes memory data
    ) public returns (uint256) {
        require(value > 0, "Value must be greater than 0");

        Proposal storage proposal = proposals[proposalCount++];
        proposal.id = proposalCount - 1;
        proposal.proposer = msg.sender;
        proposal.target = target;
        proposal.value = value;
        proposal.data = data;
        proposal.startBlock = block.number;
        proposal.endBlock = block.number + 5760; // ~1 day at 15s/block

        emit ProposalCreated(proposal.id, msg.sender, target, value, data);

        return proposal.id;
    }

    function vote(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.number >= proposal.startBlock, "Voting not started");
        require(block.number <= proposal.endBlock, "Voting closed");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 votes = token.getPastVotes(msg.sender, proposal.startBlock);
        require(votes > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit Voted(proposalId, msg.sender, support, votes);
    }

    function execute(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.number > proposal.endBlock, "Voting not ended");
        require(proposal.forVotes > proposal.againstVotes, "Proposal not approved");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Call execution failed");

        emit ProposalExecuted(proposalId);
    }
}