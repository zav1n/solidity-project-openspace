// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/math/Math.sol";
contract B {
    uint256 public count;

    function increase(uint _count) public returns(uint256) {
      count += _count;
      return count;
    }

}

contract C {
  uint256 count;

  function multicall(address target, bytes memory countcalldata) public {
    (bool success, ) = target.call(countcalldata);
    require(success, "call fail");
  }

  function delegatecallfn(address callAddr) public {
    (bool success, ) = callAddr.delegatecall(
      abi.encodeWithSignature("increase(uint256)", 10)
    );
    require(success, "delegatecall fail");
  }
}