// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenBank {
    constructor() {
        tokenBankAddr = address(this);
        owner = msg.sender;
    }

    mapping(address => uint256) balances;
    address public tokenBankAddr;
    address public owner;

    // 一个银行可以存多种token, 类似于银行有多种货币
    mapping(IERC20 => mapping(address => uint256)) erc20token;

    event Deposit(address, uint256);
    event Widthdraw(address, uint256);
    event AdminWithdraw(address, uint256);

    function deposit(IERC20 token,uint256 amount) public {
        require(amount > 0, "amount must be more than 0");
        token.transferFrom(msg.sender, address(this), amount);
        erc20token[token][msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    function widthdraw(IERC20 token) public payable {

        uint256 balance = erc20token[token][msg.sender];
        require(balance > 0,"no balance can withdraw");
        token.transfer(msg.sender, balance);
        erc20token[token][msg.sender] = 0;

        emit Widthdraw(msg.sender, balance);
    }

    function getBalance(address addr) public view returns (uint256) {
        return balances[addr];
    }

    // 管理员提取所有钱到帐户(未完善)
    // function adminWithdraw(IERC20 token) public {
    //     uint256 totalBalance = erc20token[token][msg.sender];
    //     require(totalBalance > 0, "bank no money");
    //     token.transfer(owner, totalBalance);
    //     emit AdminWithdraw(msg.sender, totalBalance);
    // }
}