// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function initialize(address _centralRegistry, uint256 _tokenId, address _quoteToken, address _baseToken) external;

    function createAndAddToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
    )  external;
    
    function addToPosition(uint256 _marginAmount, uint256 _flashLoanAmount, bytes memory _pathDefinition) external;
       function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    function removeFromPosition(
            uint256 _baseReduction, 
            uint256 _flashLoanAmount,
            bytes calldata _odosTransactionData) external;

    function closePosition(bytes memory _odosTransactionData) external;

    function MARGIN_TYPE() external view returns (uint256);

    function QUOTE_TOKEN() external view returns (address);
    function BASE_TOKEN() external view returns (address);

}