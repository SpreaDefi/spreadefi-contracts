// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/openzeppelin/token/SafeERC20.sol";
import "../interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol";
import "../interfaces/external/zerolend/IPoolAddressProvider.sol";
import "../interfaces/external/zerolend/IPool.sol";

contract Long_Quote_Odos_Zerolend is IFlashLoanSimpleReceiver {

    bool initialized;
    IPool public pool;
    IPoolAddressesProvider public addressesProvider;

    address public QUOTE_TOKEN;
    address public BASE_TOKEN;

    uint256 marginAmount;
    uint256 borrowAmount;


    error AlreadyInitialized();
    
    function initialize(address _quoteToken, address _baseToken) external {
        if(initialized) revert AlreadyInitialized();
        QUOTE_TOKEN = _quoteToken;
        BASE_TOKEN = _baseToken;
        initialized = true;
    }

    function addToPosition(
        uint256 _collateralAmount, 
        uint256 _flashLoanAmount, 
        uint256 _minTokenOut, 
        uint256 _moneyMarketBorrowAmount) external {

        marginAmount += _collateralAmount;
        
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Your custom logic here

        // Repay the loan
        uint256 totalDebt = amount + premium;
        IERC20(asset).approve(address(pool), totalDebt);
        return true;
    }

    function initiateFlashLoan(address asset, uint256 amount) external {
        bytes memory data = ""; // Add any custom parameters here
        pool.flashLoanSimple(address(this), asset, amount, data, 0);
    }

    function ADDRESSES_PROVIDER() external view override returns (IPoolAddressesProvider) {
        return addressesProvider;
    }

    function POOL() external view override returns (IPool) {
        return pool;
    }


    
    
}