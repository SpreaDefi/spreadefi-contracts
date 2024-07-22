// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Shared Storage
/// @notice Strategies use this contract to store shared storage variables to ensure storage consistency across all strategies.
/// @dev Strategies inherit this contract.

contract SharedStorage {
    /// @notice The central registry contract address
    address public centralRegistryAddress;

    /// @notice Constant representing the margin type (0 for quote, 1 for base)
    uint256 public MARGIN_TYPE;

    /// @notice The token ID representing this position
    uint256 tokenId;

    /// @notice The address of the quote token
    address public QUOTE_TOKEN;

    /// @notice The address of the base token
    address public BASE_TOKEN;
}