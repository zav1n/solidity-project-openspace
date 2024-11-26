// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract VotingToken is ERC20Votes, ERC20Permit {
  constructor(uint256 initialSupply)
    ERC20("VotingToken", "VOTE")
    ERC20Permit("VotingToken") {
      _mint(msg.sender, initialSupply);
    }
    // function _afterTokenTransfer(address from, address to, uint256 amount)
    //   internal
    //   override(ERC20, ERC20Votes)
    // {
    //   super._afterTokenTransfer(from, to, amount);
    // }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
      super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20Permit, ERC20Votes)
    {
        super._update(from, to, amount);
    }

    function nonces(address owner) public view override(ERC20Permit, ERC20Votes) returns (uint256) {
        return super.nonces(owner);
    }
}