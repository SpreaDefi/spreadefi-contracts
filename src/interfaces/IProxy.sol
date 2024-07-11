// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function initialize(uint256 _tokenId, address _quoteToken, address _baseToken) external;
    function addToPosition(uint256 _collateralAmount, uint256 _flashLoanAmount, uint256 _minTokenOut, bytes memory _pathDefinition) external;
       function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);

}