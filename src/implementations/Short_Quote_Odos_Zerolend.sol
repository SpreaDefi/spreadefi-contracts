// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/libraries/openzeppelin/token/SafeERC20.sol";
import "src/interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol";
import "src/interfaces/external/zerolend/IPoolAddressProvider.sol";
import "src/interfaces/external/zerolend/IPool.sol";
import "src/interfaces/external/odos/IOdosRouterV2.sol";
import "src/interfaces/ILeverageNFT.sol";
import "src/interfaces/IERC721A.sol";
import "src/interfaces/ICentralRegistry.sol";
import "./StrategyTemplate.sol";
import {DataTypes} from "src/interfaces/external/zerolend/DataTypes.sol";

contract Short_Quote_Odos_Zerolend is IFlashLoanSimpleReceiver, StrategyTemplate {

    using SafeERC20 for IERC20;

    /// @notice Enumeration for different actions in the strategy
    enum Action {
        ADD,
        REMOVE,
        CLOSE
    }

    /// @notice Errors for the strategy contract

    /// @notice Events for debugging purposes

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

            IPool(poolAddress).flashLoanSimple(address(this), BASE_TOKEN, _flashLoanAmount, data, 0);

        } else {

            _addPosition(0, _marginAmount, _odosTransactionData, 0);
        
        }
    }


    function _addPosition(
        uint256 _flashLoanAmount,
        uint256 _marginAddAmount,
        bytes memory _transactionData,
        uint256 _totalDebt
    ) internal {

        //1. get quote margin + flash loan base
        // 2. swap base for quote
        // 3. deposit both quote margin and swapped quote
        // 4. borrow base flash loan debt total

        IERC20 baseToken = IERC20(BASE_TOKEN);
        IERC20 quoteToken = IERC20(QUOTE_TOKEN);

        address poolAddress = ICentralRegistry(centralRegistryAddress).protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        if (_flashLoanAmount > 0) {

            // swap base for quote

            address odosRouterAddress = ICentralRegistry(centralRegistryAddress).protocols("ODOS_ROUTER");

            baseToken.safeIncreaseAllowance(odosRouterAddress, _flashLoanAmount);

            (, uint256 quoteOut) = _swapBaseForQuote(_transactionData);

            uint256 quoteTotal = _marginAddAmount + quoteOut;

            // Approve the Zerolend pool to spend the quote token
            quoteToken.safeIncreaseAllowance(poolAddress, quoteTotal);

            // deposit the quote token to the Zerolend pool
            pool.deposit(QUOTE_TOKEN, quoteTotal, address(this), 0);

            // borrow base currency using quote token as collateral
            pool.borrow(BASE_TOKEN, _totalDebt, 2, 0, address(this)); // enter the input amount
            
            // reset allowances
            quoteToken.approve(poolAddress, 0);

        } else {

            // Approve the Zerolend pool to spend the quote token
            quoteToken.safeIncreaseAllowance(poolAddress, _marginAddAmount);

            // deposit the quote token to the Zerolend pool
            pool.deposit(QUOTE_TOKEN, _marginAddAmount, address(this), 0);

        }

        quoteToken.approve(poolAddress, 0);

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

    //     IPool(poolAddress).flashLoanSimple(address(this), BASE_TOKEN, _flashLoanAmount, data, 0);

    // }


    function removeFromPosition(
        uint256 _baseReduction, 
        uint256 _flashLoanAmount,
        bytes calldata _odosTransactionData) override onlyMaster external {

        Action action = Action.REMOVE;

        bytes memory data = abi.encode(action, _baseReduction, _odosTransactionData);

        // 1. Flash loan the _flashLoanAmount
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        if (_flashLoanAmount == 0) {
            _removePosition(0, _baseReduction, _odosTransactionData, 0);
        } else {
            IPool(poolAddress).flashLoanSimple(address(this), BASE_TOKEN, _flashLoanAmount, data, 0);
        }
    }


    function _removePosition(
        uint256 _flashLoanAmount,
        uint256 _quoteReductionAmount,
        bytes memory _transactionData,
        uint256 _totalDebt
    ) internal {

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress); 

        IERC20 baseToken = IERC20(BASE_TOKEN);
        IERC20 quoteToken = IERC20(QUOTE_TOKEN);

        if (_flashLoanAmount > 0) {

            baseToken.safeIncreaseAllowance(poolAddress, _flashLoanAmount);

            pool.repay(BASE_TOKEN, _flashLoanAmount, 2, address(this));

        }

        uint256 quoteAmountUnlocked = pool.withdraw(QUOTE_TOKEN, _quoteReductionAmount, address(this));

        if (_totalDebt > 0) {

            quoteToken.safeIncreaseAllowance(odosRouterAddress, quoteAmountUnlocked);

            (uint256 quoteIn, uint256 baseOut) = _swapQuoteForBase(_transactionData);

            if (baseOut > _totalDebt) {
                // re supply the extra base token to the pool
                uint256 extra = baseOut - _totalDebt;

                baseToken.safeIncreaseAllowance(poolAddress, extra);

                pool.deposit(BASE_TOKEN, extra, address(this), 0);

            }

            if(quoteIn < _quoteReductionAmount) {
                // send to the user
                uint256 marginReturn = quoteAmountUnlocked - quoteIn;
                quoteToken.safeTransfer(_getNFTOwner(), marginReturn);
            }

        } else {
            // send to the user
            quoteToken.safeTransfer(_getNFTOwner(), quoteAmountUnlocked);
        }

        // reset allowances
        quoteToken.approve(odosRouterAddress, 0);
        baseToken.approve(poolAddress, 0);

    }

    function closePosition(bytes calldata _odosTransactionData) override onlyMaster external {
        // get the balance of the variable debt token

        (, address variableDebtTokenAddress) = _getReserveData(BASE_TOKEN);
        uint256 debtAmount = IERC20(variableDebtTokenAddress).balanceOf(address(this));

        Action action = Action.CLOSE;

        bytes memory data = abi.encode(action, debtAmount, _odosTransactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool(poolAddress).flashLoanSimple(address(this), BASE_TOKEN, debtAmount, data, 0);
    }

    function _closePosition(
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData,
        uint256 _totalDebt
    ) internal {
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        IERC20 baseToken = IERC20(BASE_TOKEN);
        IERC20 quoteToken = IERC20(QUOTE_TOKEN);

        baseToken.safeIncreaseAllowance(poolAddress, _flashLoanAmount);

        pool.repay(BASE_TOKEN, _flashLoanAmount, 2, address(this));

        (address quoteATokenAddress, ) = _getReserveData(QUOTE_TOKEN);

        uint256 baseATokenBalance = IERC20(quoteATokenAddress).balanceOf(address(this));

        IERC20(quoteATokenAddress).safeIncreaseAllowance(poolAddress, baseATokenBalance);

        pool.withdraw(QUOTE_TOKEN, baseATokenBalance, address(this));

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

        quoteToken.safeIncreaseAllowance(odosRouterAddress, baseATokenBalance);

        _swapQuoteForBase(_odosTransactionData);

        uint256 leftoverQuote = quoteToken.balanceOf(address(this));
        uint256 baseBalance = IERC20(BASE_TOKEN).balanceOf(address(this));
        uint256 leftoverBase = baseBalance - _totalDebt;

        address NFTOwner = _getNFTOwner();
        if (leftoverBase > 0) {

            IERC20(BASE_TOKEN).safeTransfer(NFTOwner, leftoverBase);
        }
        if (leftoverQuote > 0) {
   
            IERC20(QUOTE_TOKEN).safeTransfer(NFTOwner, leftoverQuote);
        }

        // reset allowances
        baseToken.approve(poolAddress, 0);
        quoteToken.approve(odosRouterAddress, 0);

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
        } else if (action == Action.CLOSE) {
            _closePosition(flashLoanAmount, odosTransactionData_, totalDebt);
        }

        IERC20(BASE_TOKEN).safeIncreaseAllowance(msg.sender, totalDebt);

        return true;
    }


    function _executeOdosTransaction(bytes memory transactionData) internal returns (bytes memory) {
        // Use a low-level call to execute the transaction

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
        (bool success, bytes memory returnData) = odosRouterAddress.call(transactionData);
        if (!success) revert SwapFailed();
 
        return returnData;

    }

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