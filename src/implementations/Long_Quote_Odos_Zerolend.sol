// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/libraries/openzeppelin/token/SafeERC20.sol";
import "./StrategyTemplate.sol";
import "src/interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol";
import "src/interfaces/external/zerolend/IPoolAddressProvider.sol";
import "src/interfaces/external/zerolend/IPool.sol";
import "src/interfaces/external/odos/IOdosRouterV2.sol";
import "src/interfaces/ILeverageNFT.sol";
import "src/interfaces/IERC721A.sol";
import "src/interfaces/ICentralRegistry.sol";
import {DataTypes} from "src/interfaces/external/zerolend/DataTypes.sol";

/// @title Long Quote Odos Zerolend Strategy Contract
/// @notice Implements a leveraged long position strategy with quote token as margin using flash loans and Odos swaps
/// @dev This contract interacts with the ZeroLend protocol and Odos router for executing leveraged trades

contract Long_Quote_Odos_Zerolend is IFlashLoanSimpleReceiver, StrategyTemplate {

    using SafeERC20 for IERC20;

    /// @notice Enumeration for different actions in the strategy
    enum Action {
        ADD,
        REMOVE,
        CLOSE
    }

    /// @dev Modifier to restrict access to the Zerolend pool
    modifier onlyZerolendPool() {
        address poolAddress = ICentralRegistry(centralRegistryAddress).protocols("ZEROLEND_POOL");
        if (msg.sender != poolAddress) revert Unauthorized();
        _;
    }

    function initialize(address _centralRegistry, uint256 _tokenId, address _quoteToken, address _baseToken) override onlyFactory external {
        centralRegistryAddress = _centralRegistry;
        tokenId = _tokenId;
        QUOTE_TOKEN = _quoteToken;
        BASE_TOKEN = _baseToken;

        MARGIN_TYPE = 0;

    }


    // function createAndAddToPosition(
    //     uint256 _marginAmount,
    //     uint256 _flashLoanAmount,
    //     bytes memory _odosTransactionData
    // ) override onlyMaster external {

    //     IERC20(QUOTE_TOKEN).safeTransferFrom(msg.sender, address(this), _marginAmount);

    //     Action action = Action.ADD;

    //     bytes memory data = abi.encode(action, _marginAmount, _odosTransactionData);

    //     ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

    //     address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

    //     IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);

    // }

    /// @notice Adds to the leveraged position using a flash loan and Odos transaction
    /// @dev This function can only be called by the master contract
    /// @param _marginAmount The amount of margin to add
    /// @param _flashLoanAmount The amount of flash loan to use
    /// @param _odosTransactionData The transaction data for the Odos swap
    function addToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
        ) override onlyMaster external {

        if (_flashLoanAmount > 0) {

            Action action = Action.ADD;

            bytes memory data = abi.encode(action, _marginAmount, _odosTransactionData);

            ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
            
            address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

            IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);

        } else {

            _addPosition(0, _marginAmount, _odosTransactionData, 0);
        }
        
    }

    /// @notice Removes from the leveraged position using a flash loan and Odos transaction
    /// @dev This function can only be called by the master contract
    /// @param _baseReduction The amount of base token to reduce
    /// @param _flashLoanAmount The amount of flash loan to use
    /// @param _odosTransactionData The transaction data for the Odos swap
    function removeFromPosition(
        uint256 _baseReduction, 
        uint256 _flashLoanAmount,
        bytes calldata _odosTransactionData) override onlyMaster external {

        if (_flashLoanAmount == 0) {
            _removePosition(0, _baseReduction, _odosTransactionData, 0);
        } else {

            Action action = Action.REMOVE;

            bytes memory data = abi.encode(action, _baseReduction, _odosTransactionData);

            // 1. Flash loan the _flashLoanAmount
            ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
            address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
            IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);

        }
    }

    /// @notice Closes the leveraged position using a flash loan and Odos transaction
    /// @dev This function can only be called by the master contract
    /// @param _odosTransactionData The transaction data for the Odos swap
    function closePosition(
        bytes calldata _odosTransactionData
    ) override onlyMaster external {
        // get the balance of the variable debt token
        (, address variableDebtTokenAddress) = _getReserveData(QUOTE_TOKEN);
        uint256 debtAmount = IERC20(variableDebtTokenAddress).balanceOf(address(this));

        Action action = Action.CLOSE;

        bytes memory data = abi.encode(action, debtAmount, _odosTransactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, debtAmount, data, 0);
    }

    /// @notice Executes the operation called by the flash loan pool
    /// @dev This function can only be called by the Zerolend pool
    /// @param asset The address of the asset being flash loaned
    /// @param flashLoanAmount The amount of the flash loan
    /// @param premium The premium to be paid on the flash loan
    /// @param initiator The initiator of the flash loan
    /// @param params The additional parameters passed during the flash loan call
    /// @return bool indicating successful execution
    function executeOperation(
        address asset,
        uint256 flashLoanAmount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) onlyZerolendPool onlySelf(initiator) external override returns (bool) {

        uint256 totalDebt = flashLoanAmount + premium;
        
        (Action action, uint256 marginAddedOrBaseReductionAmount_, bytes memory odosTransactionData_) = abi.decode(params, (Action, uint256, bytes));

        if (action == Action.ADD) {

            _addPosition(flashLoanAmount, marginAddedOrBaseReductionAmount_,odosTransactionData_, totalDebt);

        } else if (action == Action.REMOVE) {
            
            _removePosition(flashLoanAmount, marginAddedOrBaseReductionAmount_, odosTransactionData_, totalDebt);
        }
            else if (action == Action.CLOSE) {

            _closePosition(flashLoanAmount, odosTransactionData_, totalDebt);
        }

        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(msg.sender, totalDebt);

        return true;
    }


    /// @notice Executes the Odos transaction using the provided data
    /// @dev Uses a low-level call to execute the transaction
    /// @param transactionData The transaction data for the Odos swap
    /// @return bytes The return data from the Odos transaction
    function _executeOdosTransaction(bytes memory transactionData) internal returns (bytes memory) {
        // Use a low-level call to execute the transaction
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
        (bool success, bytes memory returnData) = odosRouterAddress.call(transactionData);
        if (!success) revert SwapFailed();

        return returnData;

    }

    /// @notice Swaps the quote token for the base token using Odos
    /// @param _transactionData The transaction data for the Odos swap
    /// @return quoteIn The amount of quote token swapped in
    /// @return baseOut The amount of base token received
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

    /// @notice Swaps the base token for the quote token using Odos
    /// @param _transactionData The transaction data for the Odos swap
    /// @return baseIn The amount of base token swapped in
    /// @return quoteOut The amount of quote token received
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

    /// @notice Adds to the leveraged position internally
    /// @param _flashLoanAmount The amount of flash loan to use
    /// @param _marginAddAmount The amount of margin to add
    /// @param _transactionData The transaction data for the Odos swap
    /// @param _totalDebt The total debt to be repaid
    function _addPosition(
        uint256 _flashLoanAmount,
        uint256 _marginAddAmount,
        bytes memory _transactionData,
        uint256 _totalDebt
    ) internal {

        IERC20 quoteToken = IERC20(QUOTE_TOKEN);
        IERC20 baseToken = IERC20(BASE_TOKEN);

        uint256 swapInAmount = _flashLoanAmount + _marginAddAmount;

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

        // 0. approve odos router to spend the quote token
        quoteToken.safeIncreaseAllowance(odosRouterAddress, swapInAmount);

        // 1. Swap the flash loaned (quote) amount + margin (quote) for the base token
        (,uint256 baseAmountOut) = _swapQuoteForBase(_transactionData);

        // 2. Deposit the base token to the money market
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        baseToken.safeIncreaseAllowance(poolAddress, baseAmountOut);

        pool.supply(BASE_TOKEN, baseAmountOut, address(this), 0);

        if (_totalDebt > 0) {

            // 3. Borrow the money market borrow amount
            pool.borrow(QUOTE_TOKEN, _totalDebt, 2, 0, address(this));

        }

        // transfer leftover quote token to the owner
        uint256 remainingQuoteBalance = quoteToken.balanceOf(address(this)) - _totalDebt;
        if (remainingQuoteBalance > 0) {

            quoteToken.safeTransfer(_getNFTOwner(), remainingQuoteBalance);
        }

        // reset allowances
        quoteToken.approve(odosRouterAddress, 0);
        baseToken.approve(poolAddress, 0);


    }

    /// @notice Removes from the leveraged position internally
    /// @param _flashLoanAmount The amount of flash loan to use
    /// @param _baseReductionAmount The amount of base token to reduce
    /// @param _transactionData The transaction data for the Odos swap
    /// @param _totalDebt The total debt to be repaid
    function _removePosition(
        uint256 _flashLoanAmount,
        uint256 _baseReductionAmount,
        bytes memory _transactionData,
        uint256 _totalDebt
    ) internal {

        IERC20 quoteToken = IERC20(QUOTE_TOKEN);
        IERC20 baseToken = IERC20(BASE_TOKEN);
        
        // 1. Repay part of the (QUOTE) borrowed amount to unlock collateral (BASE)
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        if(_flashLoanAmount == 0) {

            quoteToken.safeIncreaseAllowance(poolAddress, _flashLoanAmount);

            pool.repay(QUOTE_TOKEN, _flashLoanAmount, 2, address(this));

        }

        // 2. Withdraw the base token that was unlocked
        (address baseAtokenAddress,) = _getReserveData(BASE_TOKEN);

        IERC20(baseAtokenAddress).safeIncreaseAllowance(poolAddress, _baseReductionAmount);

        uint256 baseAmountUnlocked = pool.withdraw(BASE_TOKEN, _baseReductionAmount, address(this));

        // 3. Swap the unlocked base token for quote token
        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

        baseToken.safeIncreaseAllowance(odosRouterAddress, baseAmountUnlocked);

        (, uint256 quoteOut) = _swapBaseForQuote( _transactionData);

        // 4. Refund the remaining quote token

        if(_totalDebt > 0) {

            if (quoteOut > _totalDebt) {

                uint256 remainingBalance = quoteOut - _totalDebt;
        
                quoteToken.safeTransfer(_getNFTOwner(), remainingBalance);
            } 

        } else {
                quoteToken.safeTransfer(_getNFTOwner(), quoteOut);
        }

        // reset allowances
        quoteToken.approve(poolAddress, 0);
        baseToken.approve(odosRouterAddress, 0);
    }

    /// @notice Closes the leveraged position internally
    /// @param _flashLoanAmount The amount of flash loan to use
    /// @param _transactionData The transaction data for the Odos swap
    /// @param totalDebt The total debt to be repaid
    function _closePosition(
        uint256 _flashLoanAmount,
        bytes memory _transactionData,
        uint256 totalDebt
    ) internal {

        IERC20 quoteToken = IERC20(QUOTE_TOKEN);
        IERC20 baseToken = IERC20(BASE_TOKEN);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        // 1. Repay the (QUOTE) borrowed amount to unlock collateral (BASE)
        quoteToken.safeIncreaseAllowance(poolAddress, _flashLoanAmount);

        pool.repay(QUOTE_TOKEN, _flashLoanAmount, 2, address(this));

        // 2. Withdraw the base token that was unlocked
        (address baseAtokenAddress,) = _getReserveData(BASE_TOKEN);
        // get base A token balance

        uint256 baseATokenBalance = IERC20(baseAtokenAddress).balanceOf(address(this));

        uint256 baseAmountUnlocked = pool.withdraw(BASE_TOKEN, baseATokenBalance, address(this));

        // 3. Swap the unlocked base token for quote token
        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
        baseToken.safeIncreaseAllowance(odosRouterAddress, baseAmountUnlocked);
        (, uint256 amountOut) = _swapBaseForQuote( _transactionData);

        // 4. Approve the pool to transfer the necessary amount for the flash loan repayment
        if (amountOut > totalDebt) {
            quoteToken.safeIncreaseAllowance(poolAddress, amountOut);
            uint256 remainingBalance = amountOut - totalDebt;
            
            quoteToken.safeTransfer(_getNFTOwner(), remainingBalance);
        }

        // reset allowances
        quoteToken.approve(poolAddress, 0);
        baseToken.approve(odosRouterAddress, 0);

        
    }

    
    /// @notice Retrieves reserve data for a given asset
    /// @param _asset The address of the asset
    /// @return address of the aToken and the variable debt token
    function _getReserveData(address _asset) internal view returns (address, address){
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);
        DataTypes.ReserveData memory assetData = pool.getReserveData(_asset);
        address aTokenAddress = assetData.aTokenAddress;
        address variableDebtTokenAddress = assetData.variableDebtTokenAddress;
        return (aTokenAddress, variableDebtTokenAddress);
    }

    /// @notice Returns the pool addresses provider
    /// @return IPoolAddressesProvider The address of the pool addresses provider
   function ADDRESSES_PROVIDER() external view override returns (IPoolAddressesProvider) {
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address addressProviderAddress = centralRegistry.protocols("ZEROLEND_ADDRESSES_PROVIDER");
        return IPoolAddressesProvider(addressProviderAddress);
    }

    /// @notice Returns the pool addresses provider
    /// @return IPoolAddressesProvider The address of the pool addresses provider
    function POOL() external view override returns (IPool) {
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        return IPool(poolAddress);
    }
}
