// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/libraries/openzeppelin/token/SafeERC20.sol";
import "src/interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol";
import "src/interfaces/external/zerolend/IPoolAddressProvider.sol";
import "src/interfaces/external/zerolend/IPool.sol";
import "src/interfaces/external/odos/IOdosRouterV2.sol";
import "src/interfaces/ILeverageNFT.sol";
import "src/interfaces/ICentralRegistry.sol";
import {DataTypes} from "src/interfaces/external/zerolend/DataTypes.sol";

contract Long_Quote_Odos_Zerolend is IFlashLoanSimpleReceiver {

    using SafeERC20 for IERC20;

    address public centralRegistryAddress;

    uint256 public constant MARGIN_TYPE = 0; // 0 for quote, 1 for base

    uint256 tokenId; // NFT token ID that represents this position

    address public QUOTE_TOKEN;
    address public BASE_TOKEN;

    enum Action {
        ADD,
        REMOVE,
        CLOSE
    }

    error AlreadyInitialized();

    event debugUint(string, uint256);
    event debugAddress(string, address);
    event debugString(string);
    event debugBytes(string, bytes);
    
    function initialize(address _centralRegistry, uint256 _tokenId, address _quoteToken, address _baseToken) external {
        centralRegistryAddress = _centralRegistry;
        tokenId = _tokenId;
        QUOTE_TOKEN = _quoteToken;
        BASE_TOKEN = _baseToken;
    }

    // EXTERNAL FUNCTIONS

    function addToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
        ) external {

        emit debugBytes("Input Transaction Data", _odosTransactionData);

        IERC20(QUOTE_TOKEN).safeTransferFrom(msg.sender, address(this), _marginAmount); // rmemove later after testing maybe

        emit debugUint("Margin Amount", _marginAmount);

        Action action = Action.ADD;

        emit debugUint("Action Add", 0);

        bytes memory data = abi.encode(action, _marginAmount, _odosTransactionData);

        emit debugUint("Encoded data", 0);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        emit debugAddress("centralRegistry Address", address(centralRegistry));
        
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        emit debugUint("got pool address",0);

        emit debugAddress("Pool Address", poolAddress);

        IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
        
    }

    function removeFromPosition(
        uint256 _baseReduction, 
        uint256 _flashLoanAmount,
        bytes calldata _odosTransactionData) external {

        Action action = Action.REMOVE;

        bytes memory data = abi.encode(action, _baseReduction, _odosTransactionData);

        // 1. Flash loan the _flashLoanAmount
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
    }

    function closePosition(
        bytes calldata _odosTransactionData
    ) external {
        // get the balance of the variable debt token
        (, address variableDebtTokenAddress) = _getReserveData(QUOTE_TOKEN);
        uint256 debtAmount = IERC20(variableDebtTokenAddress).balanceOf(address(this));

        Action action = Action.CLOSE;

        bytes memory data = abi.encode(action, debtAmount, _odosTransactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, debtAmount, data, 0);
    }

   // INTERNAL FUNCTIONS


    // VIEW FUNCTIONS
    function _getReserveData(address _asset) internal view returns (address, address){
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);
        DataTypes.ReserveData memory assetData = pool.getReserveData(_asset);
        address aTokenAddress = assetData.aTokenAddress;
        address variableDebtTokenAddress = assetData.variableDebtTokenAddress;
        return (aTokenAddress, variableDebtTokenAddress);
    }


    function _executeOdosTransaction(bytes memory transactionData) internal returns (bytes memory) {
        // Use a low-level call to execute the transaction
        emit debugString("Executing Odos transaction");
        emit debugBytes("Transaction data", transactionData);
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
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
        uint256 quoteBalanceAfter = IERC20(QUOTE_TOKEN).balanceOf(address(this));


        quoteIn = quoteBalanceBefore - quoteBalanceAfter;

        
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

    function _addPosition(
        uint256 _flashLoanAmount,
        uint256 marginAddAmount,
        bytes memory _transactionData,
        uint256 totalDebt
    ) internal {

        uint256 swapInAmount = _flashLoanAmount + marginAddAmount;

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

        // 0. approve odos router to spend the quote token
        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(odosRouterAddress, swapInAmount);

        // 1. Swap the flash loaned (quote) amount + margin (quote) for the base token
        // IERC20(QUOTE_TOKEN).safeIncreaseAllowance(odosRouterAddress, tokenInAmount);
        (uint256 marginAmountIn,uint256 baseAmountOut) = _swapQuoteForBase(_transactionData);

        // 2. Deposit the base token to the money market
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);
        // emit balance of base token
        emit debugUint("Base token balance", IERC20(BASE_TOKEN).balanceOf(address(this)));
        IERC20(BASE_TOKEN).safeIncreaseAllowance(address(poolAddress), baseAmountOut);
        pool.supply(BASE_TOKEN, baseAmountOut, address(this), 0);

        // 3. Borrow the money market borrow amount
        pool.borrow(QUOTE_TOKEN, totalDebt, 2, 0, address(this));

        emit debugUint("Quote token balance", IERC20(QUOTE_TOKEN).balanceOf(address(this)));
        emit debugAddress("Quote token address", QUOTE_TOKEN);


        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), totalDebt);
    }

    function _removePosition(
        uint256 flashLoanAmount,
        uint256 baseReductionAmount_,
        bytes memory _transactionData,
        uint256 totalDebt
    ) internal {
        // 0. Get reserve data
        
        // 1. Repay part of the (QUOTE) borrowed amount to unlock collateral (BASE)
        emit debugUint("quote token balance", IERC20(QUOTE_TOKEN).balanceOf(address(this)));
        emit debugUint("flash loan amount", flashLoanAmount);
        emit debugUint("trying to increase allowance of debt token...",0);
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);
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
        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
        IERC20(BASE_TOKEN).safeIncreaseAllowance(odosRouterAddress, baseAmountUnlocked);
        (uint256 amountIn, uint256 amountOut) = _swapBaseForQuote( _transactionData);

        // 4. Approve the pool to transfer the necessary amount for the flash loan repayment
        if (amountOut > totalDebt) {
            IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), amountOut);
            uint256 remainingBalance = amountOut - totalDebt;
            emit debugUint("Remaining balance", remainingBalance);
            // IERC20(QUOTE_TOKEN).safeTransfer(msg.sender, remainingBalance);
        } 
    }

    function _closePosition(
        uint256 _flashLoanAmount,
        bytes memory _transactionData,
        uint256 totalDebt
    ) internal {

        emit debugUint("_closePosition", 0);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        // 1. Repay the (QUOTE) borrowed amount to unlock collateral (BASE)
        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), _flashLoanAmount);
        emit debugUint("Trying to repay...", 0);
        pool.repay(QUOTE_TOKEN, _flashLoanAmount, 2, address(this));

        // 2. Withdraw the base token that was unlocked
        (address baseAtokenAddress,) = _getReserveData(BASE_TOKEN);
        // get base A token balance

        uint256 baseATokenBalance = IERC20(baseAtokenAddress).balanceOf(address(this));

        emit debugUint("Trying to withdraw...", 0);
        uint256 baseAmountUnlocked = pool.withdraw(BASE_TOKEN, baseATokenBalance, address(this));

        emit debugUint("Base amount unlocked", baseAmountUnlocked);

        // 3. Swap the unlocked base token for quote token
        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
        IERC20(BASE_TOKEN).safeIncreaseAllowance(odosRouterAddress, baseAmountUnlocked);
        (uint256 amountIn, uint256 amountOut) = _swapBaseForQuote( _transactionData);

        emit debugUint("AMOUNT OUT AFTER SWAP", amountOut);
        emit debugUint("TOTAL DEBT", totalDebt);

        // 4. Approve the pool to transfer the necessary amount for the flash loan repayment
        if (amountOut > totalDebt) {
            IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), amountOut);
            uint256 remainingBalance = amountOut - totalDebt;
            emit debugUint("Remaining balance", remainingBalance);
            // IERC20(QUOTE_TOKEN).safeTransfer(msg.sender, remainingBalance);
        } 
    }

    // FLASH LOAN CALLBACK

    function executeOperation(
        address asset,
        uint256 flashLoanAmount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        require (msg.sender == poolAddress, "Caller is not the pool");
        require(initiator == address(this), "Initiator is not this contract");

        uint256 totalDebt = flashLoanAmount + premium;
        emit debugUint("totalDebt", totalDebt);
        
        (Action action, uint256 marginAddedOrBaseReductionAmount_, bytes memory odosTransactionData_) = abi.decode(params, (Action, uint256, bytes));

        if (action == Action.ADD) {

        emit debugUint("is add", 0);

            _addPosition(flashLoanAmount, marginAddedOrBaseReductionAmount_,odosTransactionData_, totalDebt);

        } else if (action == Action.REMOVE) {
            emit debugUint ("is remove", 0);
            
            _removePosition(flashLoanAmount, marginAddedOrBaseReductionAmount_, odosTransactionData_, totalDebt);
        }
            else if (action == Action.CLOSE) {
            emit debugUint ("is close", 2);
            _closePosition(flashLoanAmount, odosTransactionData_, totalDebt);
        }

        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), totalDebt);

        return true;
    }

    // FlashLoanSimpleReceiver
    function ADDRESSES_PROVIDER() external view override returns (IPoolAddressesProvider) {
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address addressProviderAddress = centralRegistry.protocols("ZEROLEND_ADDRESSES_PROVIDER");
        return IPoolAddressesProvider(addressProviderAddress);
    }

    function POOL() external view override returns (IPool) {
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        return IPool(poolAddress);
    }
}
