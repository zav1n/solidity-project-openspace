// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable {
        
    /**
     * initializes the token
     * @param initialOwner the initial owner
     * @param _name Token名称
     * @param _symbol symbol 表示 Token 的名称
     *
     */
    function initialize(
        address initialOwner,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init(initialOwner);
        __ERC20Permit_init(_name);
    }


    function mint(address to, uint perMint, uint totalSupplyToken) public {
        uint currentSupply = totalSupply(); // 获取当前代币供应量
        // 确保铸造后总供应量不超过最大供应量
        require(
            currentSupply + perMint <= totalSupplyToken,
            "Exceeds max total supply"
        );
        _mint(to, perMint);
    }

}
