// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LinkedBank {
    address public admin;
    mapping(address => uint256) public balances;
    // 有序的用户列表
    mapping(address => address) private _nextUsers;
    // 用户计数
    uint256 private size;
    // 哨兵节点
    address constant GUARD = address(1);

    event Withdraw(address, uint256);
    event Deposit(address, uint256);
    constructor() {
        admin = msg.sender;
        // 初始化哨兵
        _nextUsers[GUARD] = GUARD;
    }

    modifier onlyAdmin {
        require(admin == msg.sender, "only admin operate");
        _;
    }

    // 存款
    /// @param oldPreUser 旧的前置用户（需要离线查询，节省 gas）
    /// @param newPreUser 新的前置用户（需要离线查询，节省 gas）
    function deposit(address oldPreUser, address newPreUser) public payable {
        // 存款数大于 0
        require(msg.value > 0, "amount can't zero");
        // 旧的前置用户存在
        require(_isUserExist(oldPreUser), "pre user not exist");
        // 检查后置用户存在
        require(_isUserExist(newPreUser), "next user not exist");

        // 更新用户余额
        address user = msg.sender;
        uint256 newBalance = balances[user] + msg.value;
        balances[user] = newBalance;

        // 判断用户是否存在
        if (_isUserExist(user)) {
            // 用户存在，则更新用户
            _updateUser(user, newBalance, oldPreUser, newPreUser);
        } else {
            // 用户不存在，则新增用户: 新增用户的 oldPreUser 和 newPreUser相同
            _addUser(user, newBalance, oldPreUser);
        }
        
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // 提款
    function withdraw() external onlyAdmin {
        uint balance = address(this).balance;
        require(balance > 0, "contract balance is zero");
        payable(admin).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }
    
    function setAdmin(address addr) public onlyAdmin {
        require(addr != address(0), "address can not be 0");
        admin = addr;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function balanceOf(address addr) external view returns(uint256) {
        return balances[addr];
    }

    function _isUserExist(address user) internal view returns (bool) {
        return _nextUsers[user] != address(0);
    }

    function _updateUser(address user, uint256 newBalance, address preUser, address newPreUser) internal {
      // 检查用户存在
      require(_isUserExist(user), "user not exist");

      // 检查前置用户存在
      require(_isUserExist(preUser), "pre user not exist");

      // 检查后置用户存在
      require(_isUserExist(newPreUser), "next user not exist");

      // 判断前置用户和后置用户是否相同
      if (preUser == newPreUser) {
          // 相同：
          // - 检查插入节点满足金额排序的要求
          require(_verifyUser(user, newBalance, preUser, _nextUsers[preUser]), "verify user failed");
      } else {
          // 不同：
          // - 先删除用户节点
          _removeUser(user, preUser);
          // - 再新增用户节点
          _addUser(user, newBalance, preUser);
      }
    }

    function _addUser(address user, uint256 newBalance, address preUser) internal {
      // 检查用户不存在
      require(!_isUserExist(user), "user exist");

      // 检查 preUser 存在
      require(_isUserExist(preUser), "pre user not exist");

      // 检查插入节点满足金额排序的要求
      require(_verifyUser(user, newBalance, preUser, _nextUsers[preUser]), "verify user failed");

      // 新增用户
      _nextUsers[user] = _nextUsers[preUser];
      _nextUsers[preUser] = user;

      // 更新计数
      size++;
    }

    function _removeUser(address user, address preUser) internal {
        // 检查用户存在
        require(_isUserExist(user), "user not exist");

        // 检查前置用户存在
        require(_isUserExist(preUser), "pre user not exist");

        // 删除用户
        _nextUsers[preUser] = _nextUsers[user];
        _nextUsers[user] = address(0);

        // 更新计数
        size--;
    }

    // 检查金额排序:小于等于前置用户，大于等于后置用户。 注意哨兵节点的处理
    function _verifyUser(address user, uint256 newBalance, address preUser, address nextUser) internal returns (bool) {
        return (preUser == GUARD || balances[preUser] >= newBalance)
            && (nextUser == GUARD || balances[nextUser] <= newBalance);
    }

    // 获取存款金额的前 10 名用户
    function getTop10User() external view returns (address[] memory) {
        address[] memory result = new address[](10);
        address current = _nextUsers[GUARD];
        // 取 10 个，当存款人数不足 10 人时提前退出
        for (uint256 i = 0; i < 10 && i < size; i++) {
            result[i] = current;
            current = _nextUsers[current];
        }
        return result;
    }

}