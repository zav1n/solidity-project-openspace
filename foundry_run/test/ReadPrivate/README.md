题目: 使用你熟悉的语言利用 eth_getStorageAt RPC API 从链上读取 _locks 数组中的所有元素值，或者从另一个合约中设法读取esRNT中私有数组 _locks 元素数据，并打印出如下内容：
locks[0]: user:…… ,startTime:……,amount:……

> 需要把 PrivateLock 合约部署在本地(anvil)或者测试网, 否则无法运行或者测试!

资料: https://learnblockchain.cn/books/geth/part7/storage.html

```solidity
pragma solidity ^0.8.20;
contract PrivateLock {
    struct LockInfo{
        address user;
        uint64 startTime; 
        uint256 amount;
    }
    LockInfo[] private _locks;

    constructor() { 
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(address(uint160(i+1)), uint64(block.timestamp*2-i), 1e18*(i+1)));
        }
    }
}
```

![image](https://github.com/user-attachments/assets/87974cdb-8c76-4f2f-b9dc-748a5fd817ce)

<img width="602" alt="image" src="https://github.com/user-attachments/assets/6c784ce6-fef6-47dc-815d-8ee4d42b0192">



代码实现请查看: PrivateLock.t.sol

前端实现查看: https://github.com/zav1n/solidity-project-openspace/blob/v1.2.0/react_frontend/src/pages/Eth_getStorageAt.tsx


### 题目2: 使用Solidity内联汇编修改合约Owner地址

重新修改 MyWallet 合约的 transferOwernship 和 auth 逻辑，使用内联汇编方式来 set和get owner 地址。
```solidity
contract MyWallet { 
    public string name;
    private mapping (address => bool) approved;
    public address owner;

    modifier auth {
        require (msg.sender == owner, "Not authorized");
        _;
    }

    constructor(string _name) {
        name = _name;
        owner = msg.sender;
    } 

    function transferOwernship(address _addr) auth {
        require(_addr!=address(0), "New owner is the zero address");
        require(owner != _addr, "New owner is the same as the old owner");
        owner = _addr;
    }
}
```

修改后
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyWallet { 
    public string name;
    private mapping (address => bool) approved;
    public address owner;

    modifier auth {
        // 使用内联汇编验证是否是 owner
        assembly {
            // 从存储槽中加载 owner 的地址
            let ownerSlot := sload(2)  // owner 的存储槽是 2
            // 如果 msg.sender 不等于 owner，则抛出异常
            if iszero(eq(caller(), ownerSlot)) {
                revert(0, 0)
            }
        }
        _;
    }

    constructor(string memory _name) {
        name = _name;
        // 使用内联汇编设置 owner
        assembly {
            sstore(2, caller())  // 将 msg.sender 存储到 owner 的存储槽 (slot 2)
        }
    }

    function transferOwnership(address _addr) public auth {
        // 使用内联汇编检查 new owner 地址是否合法
        assembly {
            // 获取当前存储的 owner 地址
            let currentOwner := sload(2)

            // 如果新地址是零地址，抛出异常
            if iszero(_addr) {
                revert(0, 0)
            }

            // 如果新地址与当前 owner 地址相同，抛出异常
            if eq(currentOwner, _addr) {
                revert(0, 0)
            }

            // 将新的 owner 地址存储到 storage 中
            sstore(2, _addr)
        }
    }
}
```
