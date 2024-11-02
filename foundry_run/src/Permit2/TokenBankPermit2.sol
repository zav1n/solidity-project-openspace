// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice The token and amount details for a transfer signed in the permit transfer signature
struct TokenPermissions {
    // ERC20 token address
    address token;
    // the maximum amount that can be spent
    uint256 amount;
}

/// @notice The signed permit message for a single token transfer
struct PermitTransferFrom {
    TokenPermissions permitted;
    // a unique value for every token owner's signature to prevent signature replays
    uint256 nonce;
    // deadline on the permit signature
    uint256 deadline;
}

/// @notice Specifies the recipient address and amount for batched transfers.
/// @dev Recipients and amounts correspond to the index of the signed token permissions array.
/// @dev Reverts if the requested amount is greater than the permitted signed amount.
struct SignatureTransferDetails {
    // recipient address
    address to;
    // spender requested amount
    uint256 requestedAmount;
}

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface IPermit2 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}

contract TokenBank {
    IPermit2 public immutable permit2;

    mapping(address => mapping(address => uint256)) public balances;

    constructor(address _permit2) {
        require(_permit2 != address(0), "Invalid permit2");
        permit2 = IPermit2(_permit2);
    }

    function depositWithPermit2(
        IERC20 token,
        uint256 amount,
        PermitTransferFrom memory permit,
        bytes calldata signature
    ) public {
        uint256 balanceBefore = token.balanceOf(address(this));

        {
            SignatureTransferDetails memory transferDetails =
                SignatureTransferDetails({to: address(this), requestedAmount: amount});

            permit2.permitTransferFrom(permit, transferDetails, msg.sender, signature);
        }
        uint256 balanceAfter = token.balanceOf(address(this));
        // safe check for the token transfer
        require(balanceAfter - balanceBefore == amount, "Invalid token transfer");

        // update the user's balance
        balances[msg.sender][address(token)] += amount;
    }

    function withdraw(IERC20 token, uint256 amount) public {
        uint256 b = balances[msg.sender][address(token)];
        require(b >= amount, "Insufficient balance");
        balances[msg.sender][address(token)] = b - amount;
        SafeERC20.safeTransfer(token, msg.sender, amount);
    }
}