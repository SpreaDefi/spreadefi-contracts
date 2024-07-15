// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/libraries/openzeppelin/token/SafeERC20.sol";
import "src/interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol";
import "src/interfaces/external/zerolend/IPoolAddressProvider.sol";
import "src/interfaces/external/zerolend/IPool.sol";
import "src/interfaces/external/odos/IOdosRouterV2.sol";
import "src/interfaces/ILeverageNFT.sol";
import {DataTypes} from "src/interfaces/external/zerolend/DataTypes.sol";

contract Long_Quote_Odos_Zerolend is IFlashLoanSimpleReceiver {

    using SafeERC20 for IERC20;

    bool initialized;
    uint256 tokenId; // NFT token ID that represents this position

    address public QUOTE_TOKEN;
    address public BASE_TOKEN;

    uint256 public marginAmount;
    uint256 public borrowAmount;

    // ZEROLEND
    IPool public pool;
    IPoolAddressesProvider public addressesProvider;

    // ODOS
    address public odosRouterAddress;
    IOdosRouterV2 public odosRouter;

    error AlreadyInitialized();

    event debugUint(string, uint256);
    event debugAddress(string, address);
    event debugString(string);
    event debugBytes(string, bytes);
    
    function initialize(uint256 _tokenId, address _quoteToken, address _baseToken, address _pool, address _odosRouterAddress) external {
        if(initialized) revert AlreadyInitialized();
        tokenId = _tokenId;
        QUOTE_TOKEN = _quoteToken;
        BASE_TOKEN = _baseToken;
        initialized = true;
        pool = IPool(_pool);
        addressesProvider = IPoolAddressesProvider(_pool);
        odosRouterAddress = _odosRouterAddress;
        odosRouter = IOdosRouterV2(_odosRouterAddress);
    }

    // INTERNAL FUNCTIONS


    function _executeOdosTransaction(bytes memory transactionData) internal returns (bytes memory) {
        // Use a low-level call to execute the transaction
        emit debugString("Executing Odos transaction");
        emit debugBytes("Transaction data", transactionData);
        (bool success, bytes memory returnData) = odosRouterAddress.call(transactionData);
        require(success, "Odos transaction execution failed");
        emit debugString("Odos transaction executed successfully");
        return returnData;
    }

    function _swapQuoteForBase(
        bytes memory _transactionData
    ) internal returns (uint256 quoteIn, uint256 baseOut) {
        // Quote balance before swap
        uint256 quoteBalanceBefore = IERC20(QUOTE_TOKEN).balanceOf(address(this));
        
        bytes memory returnData = _executeOdosTransaction(_transactionData);

        baseOut = abi.decode(returnData, (uint256));

        // Quote balance after swap
        uint256 quoteBalanceAfter = IERC20(BASE_TOKEN).balanceOf(address(this));

        quoteIn = quoteBalanceAfter - quoteBalanceBefore;

        
    }

    function _swapBaseForQuote(
        bytes memory _transactionData
    ) internal returns (uint256 baseIn, uint256 quoteOut) {
        // Base balance before swap
        uint256 baseBalanceBefore = IERC20(BASE_TOKEN).balanceOf(address(this));
        
        bytes memory returnData = _executeOdosTransaction(_transactionData);

        quoteOut = abi.decode(returnData, (uint256));

        // Base balance after swap
        uint256 baseBalanceAfter = IERC20(BASE_TOKEN).balanceOf(address(this));

        baseIn = baseBalanceBefore - baseBalanceAfter;
    }

    // EXTERNAL FUNCTIONS

    function addToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
        ) external {

        emit debugBytes("Input Transaction Data", _odosTransactionData);

        IERC20(QUOTE_TOKEN).safeTransferFrom(msg.sender, address(this), _marginAmount); // rmemove later after testing maybe

        bool isAdd = true;

        bytes memory data = abi.encode(isAdd, _marginAmount, _odosTransactionData);

        // 1. Flash loan the _flashLoanAmount
        pool.flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
        
    }

    function removeFromPosition(
        uint256 _baseReduction, 
        uint256 _flashLoanAmount,
        bytes calldata _odosTransactionData) external {

        bool isAdd = false;

        bytes memory data = abi.encode(isAdd, _baseReduction, _odosTransactionData);

        // 1. Flash loan the _flashLoanAmount
        pool.flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
    }

    // VIEW FUNCTIONS
    function _getReserveData(address _asset) internal view returns (address, address){
        DataTypes.ReserveData memory assetData = pool.getReserveData(_asset);
        address aTokenAddress = assetData.aTokenAddress;
        address variableDebtTokenAddress = assetData.variableDebtTokenAddress;
        return (aTokenAddress, variableDebtTokenAddress);
    }

    // FLASH LOAN CALLBACK

    function executeOperation(
        address asset,
        uint256 flashLoanAmount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {

        require (msg.sender == address(pool), "Caller is not the pool");
        require(initiator == address(this), "Initiator is not this contract");

        uint256 totalDebt = flashLoanAmount + premium;
        emit debugUint("totalDebt", totalDebt);
        
        (bool isAdd, uint256 marginAddedOrBaseReductionAmount_, bytes memory odosTransactionData_) = abi.decode(params, (bool, uint256, bytes));

        if (isAdd) {

        emit debugUint("isAdd", 0);

            _addPosition(flashLoanAmount, marginAddedOrBaseReductionAmount_,odosTransactionData_, totalDebt);

        } else {
            emit debugUint ("!isAdd", 0);
            
            _removePosition(flashLoanAmount, marginAddedOrBaseReductionAmount_, odosTransactionData_, totalDebt);
        }

        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), totalDebt);

        return true;
    }

    function _addPosition(
        uint256 _flashLoanAmount,
        uint256 marginAddAmount,
        bytes memory _transactionData,
        uint256 totalDebt
    ) internal {

        uint256 swapInAmount = _flashLoanAmount + marginAddAmount;

        // 0. approve odos router to spend the quote token
        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(odosRouterAddress, swapInAmount);

        // 1. Swap the flash loaned (quote) amount + margin (quote) for the base token
        // IERC20(QUOTE_TOKEN).safeIncreaseAllowance(odosRouterAddress, tokenInAmount);
        (uint256 marginAmountIn,uint256 baseAmountOut) = _swapQuoteForBase(_transactionData);

        // 2. Deposit the base token to the money market
        IERC20(BASE_TOKEN).safeIncreaseAllowance(address(pool), baseAmountOut);
        pool.supply(BASE_TOKEN, baseAmountOut, address(this), 0);

        // 3. Borrow the money market borrow amount
        pool.borrow(QUOTE_TOKEN, totalDebt, 2, 0, address(this));

        emit debugUint("Quote token balance", IERC20(QUOTE_TOKEN).balanceOf(address(this)));
        emit debugAddress("Quote token address", QUOTE_TOKEN);

        // Accounting
        marginAmount += marginAddAmount; // amount of quote token provided as margin, does not reflect the actual margin worth. only the amount provided
        borrowAmount += baseAmountOut; // amount of base token borrowed, does not reflect the actual borrow amount if the position is partially liquidated

        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), totalDebt);
    }

    function _removePosition(
        uint256 flashLoanAmount,
        uint256 baseReductionAmount_,
        bytes memory _transactionData,
        uint256 totalDebt
    ) internal {
        // 0. Get reserve data
        (, address quoteVariableDebtTokenAddress) = _getReserveData(QUOTE_TOKEN);
        
        // 1. Repay part of the (QUOTE) borrowed amount to unlock collateral (BASE)
        emit debugUint("quote token balance", IERC20(QUOTE_TOKEN).balanceOf(address(this)));
        emit debugUint("flash loan amount", flashLoanAmount);
        emit debugUint("trying to increase allowance of debt token...",0);
        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), flashLoanAmount);
        // IERC20(quoteVariableDebtTokenAddress).safeIncreaseAllowance(address(pool), flashLoanAmount);
        emit debugUint("Trying to repay...", 0);

        pool.repay(QUOTE_TOKEN, flashLoanAmount, 2, address(this));

        // 2. Withdraw the base token that was unlocked
        (address baseAtokenAddress,) = _getReserveData(BASE_TOKEN);

        IERC20(baseAtokenAddress).safeIncreaseAllowance(address(pool), baseReductionAmount_);
        emit debugUint("Trying to withdraw...", 0);
        uint256 baseAmountUnlocked = pool.withdraw(BASE_TOKEN, baseReductionAmount_, address(this));

        emit debugUint("Base amount unlocked", baseAmountUnlocked);

        // 3. Swap the unlocked base token for quote token
        // IERC20(BASE_TOKEN).safeIncreaseAllowance(address(pool), baseAmountUnlocked);
        IERC20(BASE_TOKEN).safeIncreaseAllowance(odosRouterAddress, baseAmountUnlocked);
        (uint256 amountIn, uint256 amountOut) = _swapBaseForQuote( _transactionData);

        // 4. Approve the pool to transfer the necessary amount for the flash loan repayment
        if (amountOut > totalDebt) {
            IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), amountOut);
            uint256 remainingBalance = amountOut - totalDebt;
            emit debugUint("Remaining balance", remainingBalance);
            IERC20(QUOTE_TOKEN).safeTransfer(msg.sender, remainingBalance);
        } 
    }

    // FlashLoanSimpleReceiver
    function ADDRESSES_PROVIDER() external view override returns (IPoolAddressesProvider) {
        return addressesProvider;
    }

    function POOL() external view override returns (IPool) {
        return pool;
    }
}
