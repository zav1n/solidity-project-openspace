// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@src/IDO/IDO.sol";
import "@src/MyToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IDOTest is Test {
    IERC20 token;
    IDO public ido;
    address alice;
    function setUp() public {
        token = new MyToken("IDOT", "IDOT");
        ido = new IDO(
          address(token),
          1 ether,
          10000 ether,
          20000 ether,
          0,
          1 days
        );
        token.approve(address(ido), 10 ** 10 * 10 ** 18);
        alice = makeAddr("alice");
    }

    function test_startSale() public {
        ido.startSale();
        assertTrue(ido.isSaleActive());
    }
    function test_endSale() public {
      vm.expectRevert("sale hasn't ended yet");
      ido.endSale();
    }
    function test_buy_success() public {
        ido.startSale();
        vm.deal(alice, 1 ether); // 给用户 1 ETH

        // vm.expectRevert("less than sale price");
        // vm.prank(alice);
        // ido.buy{value: 0.1 ether}();

        vm.prank(alice);
        ido.buy{value: 1 ether}();
        assertEq(ido.balances(alice), 1 ether);
    }

    function test_settlement_success() public {
      ido.startSale();
      vm.deal(alice, 1000 ether); // 给用户 1 ETH

      vm.prank(alice);
      ido.buy{value: 1000 ether}();

      vm.warp(block.timestamp + 2 days);
      ido.endSale();
      ido.settlement();
    }

    function test_claimToken_success() public {
      ido.startSale();
      vm.deal(alice, 2222 ether); // 给用户 ETH

      vm.prank(alice);
      ido.buy{value: 2222 ether}();

      vm.warp(block.timestamp + 2 days);
      ido.endSale();

      // console.log("msg.sender", msg.sender, token.balanceOf(msg.sender));
      // console.log("address(this)", address(this), token.balanceOf(address(this)));
      // console.log("ido 合约", address(ido), token.balanceOf(address(ido)));
      // console.log("ido owner", ido.owner());
      vm.prank(alice);
      ido.claimToken();
    }

    function test_refund_success() public {
      ido.startSale();
      vm.deal(alice, 10000 ether); // 给用户 ETH

      vm.prank(alice);
      ido.buy{value: 100 ether}(); // 买入不超过募集目标, 结算时才出发可退款

      vm.warp(block.timestamp + 2 days);
      ido.endSale();
      ido.settlement();

      vm.prank(alice);
      ido.refund();
    }
}
