// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount) external;
}

contract DecertERC20 is IERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    // event Transfer(address indexed from, address indexed to, uint256 value);
    // event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory tokenName, string memory tokenSymbol) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = 18;
        totalSupply = 100_000_000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];

    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require(_to != address(0), "ERC20: transfer amount exceeds balance");
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "can't be transfer zero address");
        require(balances[_from] >= _value, "ERC20: transferFrom amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "invalid address");
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining) {   
        return allowances[_owner][_spender];
    }

    // 转帐, recipient 可能是合约或者用户
    function transferWithCallback(address recipient, uint256 _value) external returns (bool) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        (bool success) = transfer(recipient, _value);
        require(success, "transfer fail");
        // 是否是合约
        if (isContract(recipient)) {
            ITokenReceiver(recipient).tokensReceived(msg.sender, _value);
        }

        return true;
    }

    function isContract(address addr) public view returns(bool) {
         return addr.code.length != 0;
    }
}