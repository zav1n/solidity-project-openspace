pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TokenPermit is ERC20Permit, Ownable {
    constructor(
      string memory tokenName,
      string memory tokenSymbol,
      uint256 initialSupply
    ) ERC20(tokenName, tokenSymbol) ERC20Permit(tokenName) Ownable(msg.sender) {
      _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function getPermitTypehash() public pure returns (bytes32) {
        return keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    // 等同于 token.DOMAIN_SEPARATOR();  ERC20Permit提供的DOMAIN_SEPARATOR方法
    function getDomainSeparator() public view returns (bytes32) {
        return _domainSeparatorV4();
    }
}



