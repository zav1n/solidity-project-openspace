// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 编写一个 Bank 合约，实现功能：
// 可以通过 Metamask 等钱包直接给 Bank 合约地址存款
// 在 Bank 合约记录每个地址的存款金额
// 编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
// 用数组记录存款金额的前 3 名用户
// 请提交完成项目代码或 github 仓库地址。

contract Bank {
    address public admin; // 管理员地址
    uint public minIndex;
    constructor() {
        admin = msg.sender;
    }

    mapping(address => uint) public balances;
    // mapping(address => account) public accounts;

    struct Accounts {
        address addr;
        uint balance;
    }

    Accounts[] public top_three_list;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin can be operate");
        _;
    }

    function deposit() external payable {
        require(msg.value > 0, "amount must be more than 0");
        balances[msg.sender] += msg.value;
        top_three(msg.sender);
    }

    function getContractBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() external payable onlyAdmin {
        uint allBalance = address(this).balance;
        payable(admin).transfer(allBalance);
    }

    function top_three(address sender) internal {
        uint256 senderInContractAmount = balances[sender];

        if(top_three_list.length < 3) {
            top_three_list.push(Accounts({addr: sender, balance: senderInContractAmount}));
        } else {
            for(uint i = 0; i < top_three_list.length; i++) {
                if(top_three_list[i].balance < top_three_list[minIndex].balance) {
                    minIndex = i;
                }
            }

            if(senderInContractAmount > top_three_list[minIndex].balance) {
                top_three_list[minIndex] = Accounts({addr: sender, balance: senderInContractAmount});
            }
        }
    }

    function getTopThree() external view returns(Accounts[] memory) {
        return top_three_list;
    }
}