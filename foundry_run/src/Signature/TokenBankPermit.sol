// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TokenBank {
    address public tokenBankAddr;
    address public admin;

    constructor() {
        tokenBankAddr = address(this);
        admin = msg.sender;
    }


    // 一个银行可以存多种token, 类似于银行有多种货币
    mapping(IERC20 => mapping(address => uint256)) balances;

    event Deposit(address, uint256);
    event Widthdraw(address, uint256);

    function deposit(IERC20 token,uint256 amount) public {
        require(amount > 0, "amount must be more than 0");
        token.transferFrom(msg.sender, address(this), amount);
        balances[token][msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    function widthdraw(IERC20 token) public payable {

        uint256 balance = balances[token][msg.sender];
        require(balance > 0,"no balance can withdraw");
        token.transfer(msg.sender, balance);
        balances[token][msg.sender] = 0;

        emit Widthdraw(msg.sender, balance);
    }

    function getBalance(IERC20 token, address _addr) public view returns (uint256) {
        return balances[token][_addr];
    }
    
    function permitDeposit(
        IERC20 _token,
        address _from,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {

        ERC20Permit(address(_token)).permit(_from, address(this), value, deadline, v, r, s);

        require(_token.transferFrom(_from, address(this), value), "Transfer failed");
        balances[_token][_from] += value;
        
        emit Deposit(_from, value);
    }

}