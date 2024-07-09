// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/openzeppelin/token/SafeERC20.sol";
import "../interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol";
import "../interfaces/external/zerolend/IPoolAddressProvider.sol";
import "../interfaces/external/zerolend/IPool.sol";
import "../interfaces/external/odos/IOdosRouterV2.sol";

contract Long_Quote_Odos_Zerolend is IFlashLoanSimpleReceiver {

    using SafeERC20 for IERC20;

    bool initialized;

    address public QUOTE_TOKEN;
    address public BASE_TOKEN;

    uint256 marginAmount;
    uint256 borrowAmount;

    // ZEROLEND
    IPool public pool;
    IPoolAddressesProvider public addressesProvider;

    // ODOS
    address public odosRouterAddress;
    IOdosRouterV2 public odosRouter;

    error AlreadyInitialized();
    
    function initialize(address _quoteToken, address _baseToken) external {
        if(initialized) revert AlreadyInitialized();
        QUOTE_TOKEN = _quoteToken;
        BASE_TOKEN = _baseToken;
        initialized = true;
    }

    // INTERNAL FUNCTIONS

    function _performSwap(
        address initiator, // saves gas
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 outputQuote,
        uint256 outputMin,
        bytes memory pathDefinition 
    ) internal returns (uint256 amountOut) {
        IOdosRouterV2.swapTokenInfo memory tokenInfo = IOdosRouterV2.swapTokenInfo({
            inputToken: inputToken,
            inputAmount: inputAmount,
            inputReceiver: initiator,
            outputToken: outputToken,
            outputQuote: outputQuote,
            outputMin: outputMin,
            outputReceiver: msg.sender
        });

        if (inputToken == address(0)) {
            require(msg.value == inputAmount, "Incorrect ETH amount");
            amountOut = odosRouter.swap(tokenInfo, pathDefinition, address(this), uint32(0));
        } else {
            IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
            IERC20(inputToken).safeIncreaseAllowance(odosRouterAddress, inputAmount);
            amountOut = odosRouter.swap(tokenInfo, pathDefinition, address(this), uint32(0));
        }

        return amountOut;
    }

    // EXTERNAL FUNCTIONS

    function addToPosition(
        uint256 _marginAmount, 
        uint256 _flashLoanAmount, 
        uint256 _minTokenOut,
        bytes calldata _pathDefinition
        ) external {

        bool isAdd = true;

        bytes memory data = abi.encode(isAdd, _marginAmount, _flashLoanAmount, _minTokenOut, _pathDefinition);

        // 1. Flash loan the _flashLoanAmount
        pool.flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
        
    }

    function removeFromPosition(uint256 _baseRepayAmount) external {

        bool isAdd = false;

        bytes memory data = abi.encode(isAdd);
    }

    // FLASH LOAN CALLBACK

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {

        require (msg.sender == address(pool), "Caller is not the pool");

        require(initiator == address(this), "Initiator is not this contract");

        uint256 totalDebt = amount + premium;
        
        (bool isAdd, uint256 marginAmount_, uint256 flashLoanAmount_, uint256 minTokenOut_, bytes memory pathDefinition_) = abi.decode(params, (bool, uint256, uint256, uint256, bytes));

        // if isAdd, then add to position
        if (isAdd) {

            uint256 tokenInAmount = flashLoanAmount_ + marginAmount_;

            // 1. Swap the flash loaned (quote) amount + margin (quote) for the base token
            uint256 amountOut = _performSwap(initiator, QUOTE_TOKEN, tokenInAmount, BASE_TOKEN, minTokenOut_, minTokenOut_, pathDefinition_);

            if (amountOut > minTokenOut_) {
                uint256 extraBaseToken = amountOut - minTokenOut_;
                amountOut += extraBaseToken; // Add extra base token to the amount out
            }

            // 2. Deposit the base token to the money market
            pool.supply(BASE_TOKEN, amountOut, initiator, 0);

            // 3. Borrow the money market borrow amount
            pool.borrow(BASE_TOKEN, totalDebt, 1, 0, initiator);

            // Accounting
            marginAmount += marginAmount_;

        } 
        // if isAdd is false, then remove from position
        else {


        }

        // Repay the loan
        
        IERC20(asset).approve(address(pool), totalDebt);
        return true;
    }

    // FlashLoanSimpleReceiver
    function ADDRESSES_PROVIDER() external view override returns (IPoolAddressesProvider) {
        return addressesProvider;
    }

    function POOL() external view override returns (IPool) {
        return pool;
    }
}
