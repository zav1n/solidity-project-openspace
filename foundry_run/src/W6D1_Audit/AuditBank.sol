// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

contract AuditBank is  AutomationCompatibleInterface, ReentrancyGuard, Ownable(msg.sender) {
    uint256 public MAX_SUPPLY = 1000 ether;

    mapping(address => uint256) balances;
    // support different token
    mapping(IERC20 => mapping(address => uint256)) erc20token;

    event Deposit(address, uint256);
    event Widthdraw(address, uint256);
    event AdminWithdraw(address, uint256);

    function deposit(address tokenAddr,uint256 amount) public {
        require(amount > 0, "amount must be more than 0");
        IERC20(tokenAddr).transferFrom(msg.sender, address(this), amount);
        erc20token[IERC20(tokenAddr)][msg.sender] += amount;
        balances[tokenAddr] += amount;

        emit Deposit(msg.sender, amount);
    }

    function widthdraw(address tokenAddr) public {
        uint256 balance = erc20token[IERC20(tokenAddr)][msg.sender];
        require(balance > 0,"no balance can withdraw");
        erc20token[IERC20(tokenAddr)][msg.sender] = 0;
        IERC20(tokenAddr).transfer(msg.sender, balance);

        emit Widthdraw(msg.sender, balance);
    }

    function getBalance(address tokenAddr) external view returns (uint256) {
        return erc20token[IERC20(tokenAddr)][msg.sender];
    }
    function getTokenBalance(address tokenAddr) external view returns (uint256) {
      return balances[tokenAddr];
    }

    function setmaxsupply(uint256 maxSupply) external {
      MAX_SUPPLY = maxSupply;
    }

    function checkUpkeep(bytes memory checkData) external view returns(bool, bytes memory) {
      address tokenAddr = abi.decode(checkData, (address));
      return(balances[tokenAddr] >= MAX_SUPPLY, abi.encode(tokenAddr, MAX_SUPPLY));
    }
    
    function performUpkeep(bytes calldata performData) external {
      (address tokenAddr, uint256 maxSupply) = abi.decode(performData, (address, uint256));
      if(balances[tokenAddr] >= maxSupply) {
        uint256 transferAmount = balances[tokenAddr] / 2;
        balances[tokenAddr] -= transferAmount;
        IERC20(tokenAddr).transfer(owner(), transferAmount);
        emit AdminWithdraw(owner(), transferAmount);
      }
    }
}