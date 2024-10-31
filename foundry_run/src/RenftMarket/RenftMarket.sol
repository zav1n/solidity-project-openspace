// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title RenftMarket
 * @dev NFT租赁市场合约
 *   TODO:
 *      1. 退还NFT：租户在租赁期内，可以随时退还NFT，根据租赁时长计算租金，剩余租金将会退还给出租人
 *      2. 过期订单处理：
 *      3. 领取租金：出租人可以随时领取租金
 */
contract RenftMarket is EIP712 {
  // 出租订单事件
  event BorrowNFT(address indexed taker, address indexed maker, uint256 token_id, uint256 collateral);
  // 取消订单事件
  event OrderCanceled(address indexed maker, uint256 token_id);

  mapping(uint256 => BorrowOrder) public orders; // 已租赁订单
  mapping(uint256 => bool) public canceledOrders; // 已取消的挂单

  bytes32 public constant PERMIT_TYPEHASH = keccak256("RentoutOrder(address maker,address nft_ca,uint256 token_id,uint256 daily_rent,uint256 max_rental_duration,uint256 min_collateral,uint256 list_endtime)");
  constructor() EIP712("RenftMarket", "1") { }

  /**
   * @notice 租赁NFT
   * @dev 验证签名后，将NFT从出租人转移到租户，并存储订单信息
   */
  function borrow(RentoutOrder calldata order, bytes calldata makerSignature) external payable {
    // 获取structHash
    // 验证签名 _verify
    require(_verify(order, makerSignature), "Invalid signature");

    // 检查订单有效性
    require(block.timestamp <= order.list_endtime, "Order expired");
    require(!canceledOrders[order.token_id], "Order is canceled");
    require(msg.value >= order.min_collateral, "Insufficient collateral");

    // 支付 ETH 给出租人
    uint256 totalPayment = order.daily_rent;
    require(msg.value >= totalPayment, "Insufficient payment for rent");
    // 转账给出租人
    payable(order.maker).transfer(totalPayment);
    // 进行 NFT 转移
    IERC721(order.nft_ca).transferFrom(order.maker, msg.sender, order.token_id);

    // 记录租赁信息
    orders[order.token_id] = BorrowOrder({
        taker: msg.sender,
        collateral: msg.value,
        start_time: block.timestamp,
        rentinfo: order
    });

    canceledOrders[order.token_id] = true;
    
    // 触发BorrowNFT事件
    emit BorrowNFT(msg.sender, order.maker, order.token_id, msg.value);

  }

  /**
   * 1. 取消时一定要将取消的信息在链上标记，防止订单被使用！
   * 2. 防DOS： 取消订单有成本，这样防止随意的挂单，
   */
  function cancelOrder(RentoutOrder calldata order, bytes calldata makerSignature) external {
    // 验证签名
    require(_verify(order, makerSignature), "Invalid signature");

    // 获取租赁信息
    BorrowOrder memory borrowOrder = orders[order.token_id];
    require(borrowOrder.taker != address(0), "Order not found");

    // 计算租赁时长
    uint256 rentalDay = (block.timestamp - borrowOrder.start_time) / 1 days;
    // 计算租金
    uint256 totalRent = rentalDay * borrowOrder.rentinfo.daily_rent;
    // 计算取消成本，例如，扣除押金的一部分
    uint256 cancelCost = (borrowOrder.collateral * 10) / 100; // 例如，取消时扣除10%的押金

    // 租金支付给出租人
    uint256 amountToPay = totalRent > cancelCost ? totalRent : cancelCost;
    payable(order.maker).transfer(amountToPay);

    // NFT 转回拥有者
    IERC721(order.nft_ca).transferFrom(borrowOrder.taker, borrowOrder.rentinfo.maker, borrowOrder.rentinfo.token_id);

    // 清除订单信息
    delete orders[order.token_id];

    emit OrderCanceled(order.maker, order.token_id);
  }

  // 计算订单哈希
  function orderHash(RentoutOrder calldata order) public view returns (bytes32) {
    return _hashTypedDataV4(keccak256(
      abi.encode(
        PERMIT_TYPEHASH,
        order.maker,
        order.nft_ca,
        order.token_id,
        order.daily_rent,
        order.max_rental_duration,
        order.min_collateral
      ))
    );
  }

  function _verify(RentoutOrder calldata order, bytes memory signature) internal view returns (bool) {
    bytes32 hashStruct = orderHash(order);
    bytes32 sig =  keccak256(abi.encodePacked("\x19\x01", getDomain(), hashStruct));
    return order.maker == ECDSA.recover(sig, signature);
  }

  function getDomain() public view returns (bytes32) {
    return _domainSeparatorV4();
  }

  struct RentoutOrder {
    address maker; // 出租方地址
    address nft_ca; // NFT合约地址
    uint256 token_id; // NFT tokenId
    uint256 daily_rent; // 每日租金
    uint256 max_rental_duration; // 最大租赁时长
    uint256 min_collateral; // 最小抵押
    uint256 list_endtime; // 挂单结束时间
  }

  // 租赁信息
  struct BorrowOrder {
    address taker; // 租方人地址
    uint256 collateral; // 抵押
    uint256 start_time; // 租赁开始时间，方便计算利息
    RentoutOrder rentinfo; // 租赁订单
  }
}
