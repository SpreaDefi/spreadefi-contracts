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
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        uint256 minTokenOut;
        bytes pathDefinition;
    }

    function createPosition(NewPositionParams memory params) external;
}