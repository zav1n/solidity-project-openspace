// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;
  
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract IDO is ReentrancyGuard{
  IERC20 public token;  // token
  address public owner;

  uint256 public salePrice; // 预售价格
  uint256 public collectTarget; // 募集ETH目标
  uint256 public exceedTarget; // 超募上限
  uint256 public startTime; // 开始时间
  uint256 public endSaleTime; // 预售时长

  uint256 public poolTotalPrice; // 已募集的总金额

  bool public isSaleActive;
  bool public isSaleEnd;
  bool public isRefundEnable;

  mapping(address => uint256) public balances;

  event OwnerWithdraw(address,uint256);
  event RefundEnabled(bool);
  constructor(
    address _token,
    uint256 _salePrice,
    uint256 _collectTarget,
    uint256 _exceedTarget,
    uint256 _startTime,
    uint256 _endTime
  ) {
    owner = msg.sender;
    token = IERC20(_token);
    salePrice = _salePrice;
    collectTarget = _collectTarget;
    exceedTarget = _exceedTarget;
    startTime = block.timestamp + _startTime;
    endSaleTime = block.timestamp + _endTime;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only owner execute");
    _;
  }

  // modifier () {
  //   require(isSaleActive, "sale is not active");
  //   require(isSaleEnd == false, "sale is not end");
  //   _;
  // }


  function startSale() external onlyOwner {
    require(block.timestamp >= startTime, "not yet time to start");
    isSaleActive = true;
  }

  function endSale() external onlyOwner {
    require(block.timestamp >= endSaleTime, "sale hasn't ended yet");
    isSaleEnd = true;
  }

  function buy() external payable {
    require(isSaleActive, "sale is not active");
    require(isSaleEnd == false, "sale is not end");
    require(msg.value >= salePrice, "less than sale price");
    require(msg.value + poolTotalPrice <= exceedTarget, "exceed pool target collect");

    poolTotalPrice += msg.value;
    balances[msg.sender] += msg.value;
  }
  
  // 结算
  function settlement() external onlyOwner {
    require(isSaleEnd, "winthdraw fail");
    if(poolTotalPrice < collectTarget) {
      isRefundEnable = true;
      emit RefundEnabled(true);
    } else {
      payable(owner).transfer(poolTotalPrice);
      emit OwnerWithdraw(owner, poolTotalPrice);
    }
  }

  function claimToken() external {
    require(!isRefundEnable && isSaleEnd, "claim condition not met");
    require(balances[msg.sender] > 0, "No value to claim");

    uint256 tokensToClaim = (balances[msg.sender] * 10**18) / salePrice;
    balances[msg.sender] = 0; // 防止重入
    token.transferFrom(owner, msg.sender, tokensToClaim);
  }

  function refund() external {
    require(isRefundEnable && isSaleEnd, "refund condition not met");
    require(balances[msg.sender] > 0, "Invalid refund");

    // 防止重入
    uint256 refundValue = balances[msg.sender];
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(refundValue);
  }
}