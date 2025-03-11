// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20Token is IERC20 {
  string public name;
  string public symbol;
  uint256 public totalSupply;
  uint8 public decimals = 18;
  uint256 public immutable limitedSupply = 1_000_000 * 10 ** 18;
  address public owner;
  bool public paused;
  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowances;

  event Mint(address indexed to, uint256 amount);
  event Burn(uint256 amount);
  // 由于 Transfer 事件已在 IERC20 接口中定义，此处无需重复定义
  event Pause(bool paused);

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  modifier whenNotPaused() {
    require(paused == false, "Transfer paused");
    _;
  }

  function mint(address to, uint256 amount) external onlyOwner {
    require(to != address(0), "Invalid address");
    require(totalSupply + amount <= limitedSupply, "Amount exceeds limited supply");
    totalSupply += amount;
    balances[to] += amount;
    emit Mint(to, amount);
    // emit Transfer(msg.sender, to, amount);
  }

  function burn(uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;
    totalSupply -= amount;
    emit Burn(amount);
  }
  
  function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
    require(to != address(0), "Invalid address");
    require(balances[msg.sender] >= value, "transfer amount exceeds balance");

    balances[msg.sender] -= value;
    balances[to] += value;

    emit Transfer(msg.sender, to, value);
    return true;
  }
  function transferFrom(address from, address to, uint256 amount) external whenNotPaused returns(bool) {
    require(to!= address(0), "Invalid address");
    require(balances[from] >= amount, "transfer amount exceeds balance");
    require(allowances[from][msg.sender] >= amount, "allowance amount exceeds balance");
    balances[from] -= amount;
    balances[to] += amount;
    allowances[from][msg.sender] -= amount;
    emit Transfer(from, to, amount);
    return true;
  }

  function approve(address to, uint256 amount) external returns(bool){
    require(to!= address(0), "Invalid address");
    // require(balances[msg.sender] >= amount, "transfer amount exceeds balance");
    allowances[msg.sender][to] = amount;
    emit Approval(msg.sender, to, amount);
    return true;
  }

  function allowance(address _owner, address spender) external view returns(uint256) {
    return allowances[_owner][spender];
  }

  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  function togglePause() external onlyOwner {
    paused = !paused;
    emit Pause(paused);
  }

}