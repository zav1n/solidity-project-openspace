// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Bank.sol";


contract TokenBankV2 is Bank {
    function tokensReceived(address from,uint256 amount) public {
        balances[from] += amount;
    }
}