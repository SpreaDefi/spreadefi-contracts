// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function initialize(address _quoteToken, address _baseToken) external;
    function addToPosition(uint256 _collateralAmount, uint256 _flashLoanAmount, uint256 _minTokenOut, bytes memory _pathDefinition) external;

}