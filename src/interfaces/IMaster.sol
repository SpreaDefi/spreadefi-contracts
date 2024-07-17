// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMaster {
    enum PositionType {
        LONG,
        SHORT
    }

    enum MarginType {
        QUOTE,
        BASE
    }

    struct NewPositionParams {
        address implementation;
        address quoteToken;
        address baseToken;
    }

    struct PositionParams {
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        bytes pathDefinition;
    }

    function createPosition(NewPositionParams memory params) external;

    function addToPosition(uint256 _tokenId, PositionParams memory params) external;

    function removeFromPosition(uint256 _tokenId, uint256 _baseReductionAmount, uint256 _flashLoanAmount, bytes memory _transactionData) external;

    function closePosition(uint256 _tokenId, bytes memory _transactionData) external;
    
}