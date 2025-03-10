// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// 编写一个简单的银行合约，包含存款、取款功能，并实现防重入攻击的保护措施。
contract Bank {
  constructor() {
    owner = msg.sender;
  }

  address private owner;

  event Deposit(address indexed user, uint256 amount, uint256 timestamp);
  event Withdraw(address indexed user, uint256 amount, uint256 timestamp);

  mapping(address => uint256) public balances;

  bool private locked;
  modifier noReentrancy(){
    require(!locked, "no reentrancy");
    locked = true;
    _;
    locked = false;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner, "only owner");
    _;
  }

  function deposit() external payable {
    require(msg.value > 0, "not enough amount");
    balances[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value, block.timestamp);
  }

  function withdraw(uint amount) external noReentrancy {
    require(balances[msg.sender] >= amount, "not enough balance");
    balances[msg.sender] -= amount;
    emit Withdraw(msg.sender, amount, block.timestamp);

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "withdraw failed"); 

  }

  function getBalance() external view returns(uint256){
    return balances[msg.sender];
  }

  function contractAmount() external view onlyOwner returns(uint256) {
    return address(this).balance;
  }
}