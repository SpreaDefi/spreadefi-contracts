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

contract Short_Base_Odos_Zerolend is StrategyTemplate, IFlashLoanSimpleReceiver {
    
    using SafeERC20 for IERC20;

    /// @notice Enumeration for different actions in the strategy
    enum Action {
        ADD,
        REMOVE,
        CLOSE
    }

    /// @notice Events for debugging purposes
    event debugUint(string, uint256);
    event debugAddress(string, address);
    event debugString(string);
    event debugBytes(string, bytes);

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

        MARGIN_TYPE = 1;
    }


    function addToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
    ) override onlyMaster external {

        IERC20(BASE_TOKEN).safeTransferFrom(_getNFTOwner(), address(this), _marginAmount);

        Action action = Action.ADD;

        bytes memory data = abi.encode(action, _marginAmount, _odosTransactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        IPool(poolAddress).flashLoanSimple(address(this), BASE_TOKEN, _flashLoanAmount, data, 0);
    }

    function _addPosition(
        uint256 _marginAddAmount,
        uint256 _flashLoanAmount,
        bytes memory _transactionData,
        uint256 _totalDebt
    ) internal {

        IERC20 baseToken = IERC20(BASE_TOKEN);
        IERC20 quoteToken = IERC20(QUOTE_TOKEN); 

        address odosRouterAddress = ICentralRegistry(centralRegistryAddress).protocols("ODOS_ROUTER");
        address poolAddress = ICentralRegistry(centralRegistryAddress).protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        uint256 baseTotal = _flashLoanAmount + _marginAddAmount;

        // Approve the flash loan amount + flashLoanAmount to the Odos Router
        baseToken.safeIncreaseAllowance(odosRouterAddress, _flashLoanAmount + baseTotal);

        (uint256 baseIn, uint256 quoteOut) = _swapBaseForQuote(_transactionData);

        // approve quote token to the lending pool
        quoteToken.safeIncreaseAllowance(poolAddress, quoteOut);

        // lend quote token to the pool
        pool.deposit(QUOTE_TOKEN, quoteOut, address(this), 0);

        emit debugUint("trying to borrow...", _totalDebt);
        pool.borrow(BASE_TOKEN, _totalDebt, 2, 0, address(this));
        
        // get leftover base amount
        uint256 baseBalance = baseToken.balanceOf(address(this));
        uint256 leftoverBase = baseBalance - _totalDebt;

        if (leftoverBase > 0) {
            baseToken.safeTransfer(_getNFTOwner(), leftoverBase);
        }

        // reset approvals
        baseToken.approve(odosRouterAddress, 0);
        quoteToken.approve(poolAddress, 0);
        
    }

    function createAndAddToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
    ) override onlyMaster external {

        IERC20(BASE_TOKEN).safeTransferFrom(msg.sender, address(this), _marginAmount);

        Action action = Action.ADD;

        bytes memory data = abi.encode(action, _marginAmount, _odosTransactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);

    }

    function removeFromPosition(
        uint256 _quoteReductionAmount,
        uint256 _flashLoanAmount,
        bytes memory _transactionData
    ) override onlyMaster external {
        Action action = Action.REMOVE;

        bytes memory data = abi.encode(action, _quoteReductionAmount, _transactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        IPool(poolAddress).flashLoanSimple(address(this), BASE_TOKEN, _flashLoanAmount, data, 0);
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

        baseToken.safeIncreaseAllowance(poolAddress, _flashLoanAmount);

        pool.repay(BASE_TOKEN, _flashLoanAmount, 2, address(this));

        uint256 quoteAmountUnlocked = pool.withdraw(QUOTE_TOKEN, _quoteReductionAmount, address(this));

        quoteToken.safeIncreaseAllowance(odosRouterAddress, quoteAmountUnlocked);

        (uint256 quoteIn, uint256 baseOut) = _swapQuoteForBase(_transactionData);

        if(quoteIn < quoteAmountUnlocked) {
            quoteToken.safeIncreaseAllowance(poolAddress, quoteAmountUnlocked - quoteIn);
            pool.deposit(QUOTE_TOKEN, quoteAmountUnlocked - quoteIn, address(this), 0);
        }
        if (baseOut > _totalDebt) {
            uint256 marginReturn = baseOut - _totalDebt;
            baseToken.safeTransfer(_getNFTOwner(), marginReturn);
        }

        // reset approvals
        baseToken.approve(poolAddress, 0);
        quoteToken.approve(odosRouterAddress, 0);
        quoteToken.approve(poolAddress, 0);
    }

    function closePosition(bytes calldata _odosTransactionData) override onlyMaster external {
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
        uint256 _totalDebt)
    internal {
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

        uint256 amountUnlocked = pool.withdraw(QUOTE_TOKEN, baseATokenBalance, address(this));

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

        quoteToken.safeIncreaseAllowance(odosRouterAddress, amountUnlocked);

        _swapQuoteForBase(_odosTransactionData);

        uint256 leftoverQuote = quoteToken.balanceOf(address(this));
        uint256 baseBalance = IERC20(BASE_TOKEN).balanceOf(address(this));
        uint256 leftoverBase = baseBalance - _totalDebt;

        address NFTOwner = _getNFTOwner();
        if(leftoverBase > 0) {
            baseToken.safeTransfer(NFTOwner, leftoverBase);
        }
        if(leftoverQuote > 0) {
            quoteToken.safeTransfer(NFTOwner, leftoverQuote);
        }

        // reset approvals
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

        emit debugUint("odos transaction executed", 0);

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

        IERC20(BASE_TOKEN).safeIncreaseAllowance(msg.sender, totalDebt);

        return true;
    }

    function _executeOdosTransaction(bytes memory transactionData) internal returns (bytes memory) {
        // Use a low-level call to execute the transaction
        emit debugString("Executing Odos transaction");
        emit debugBytes("Transaction data", transactionData);
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
        (bool success, bytes memory returnData) = odosRouterAddress.call(transactionData);
        if (!success) revert SwapFailed();
        emit debugString("Odos transaction executed successfully");
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