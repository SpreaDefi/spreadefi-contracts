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
        string implementation;
        address quoteToken;
        address baseToken;
    }

    struct PositionParams {
        uint256 marginAmountOrCollateralReductionAmount;
        uint256 flashLoanAmount;
        bytes pathDefinition;
    }

    function createPosition(NewPositionParams memory params) external returns (uint256 tokenId, address proxyAddress);

    function createAndAddToPosition(NewPositionParams memory _newPositionParams, PositionParams memory _positionParams, address _OnBehalfOf) external returns (uint256 tokenId, address proxyAddress);

    function addToPosition(uint256 _tokenId, PositionParams memory params) external;

    function removeFromPosition(uint256 _tokenId, PositionParams memory params) external;

    function closePosition(uint256 _tokenId, bytes memory _transactionData) external;
    
}