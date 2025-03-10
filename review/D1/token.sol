// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 问题 ：编写一个简单的代币合约，实现铸造和转账功能，并确保防止整数溢出/下溢。
contract Token {
  address public owner;
  uint8 public decimals = 18;
  string public name;
  string public symbol;
  uint256 public totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint256)) private allowances;

  event Mint(address indexed to, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed from, address indexed spender, uint256 amount);
  constructor(string memory _name, string memory _symbol) {
    owner = msg.sender;
    name = _name;
    symbol = _symbol;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "only owner");
    _;
  }

  
  // 铸造新代币 - 仅合约拥有者可调用
  function mint(address to, uint amount) external onlyOwner {
    require(to != address(0), "to address is zero");
    balances[to] += amount;
    totalSupply += amount;

    emit Mint(to, amount);
  }

  function transfer(address to, uint amount) external returns(bool) {
    require(balances[msg.sender] >= amount, "balance is not enough");
    require(to != address(0), "to address is zero");
    balances[msg.sender] -= amount;
    balances[to] += amount;

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(address from, address to, uint amount) external returns(bool) {
    require(from != address(0) && to != address(0), "from address is zero");
    require(balances[from] >= amount, "balance is not enough");
    require(allowances[from][msg.sender] >= amount ,"allowance not enough");

    allowances[from][msg.sender] -= amount;
    balances[from] -= amount;
    balances[to] += amount;

    emit Transfer(from, to, amount);
    return true;
  }

  function approve(address to,uint amount) external returns(bool) {
    require(to != address(0), "to address is zero");
    allowances[msg.sender][to] = amount;

    emit Approval(msg.sender, to, amount);

    return true;
  }

  // 查询授权额度
  function allowance(address user,address spender) external view returns (uint) {
    return allowances[user][spender];
  }

  function balanceOf(address account) external view returns (uint) {
    return balances[account];
  }

}