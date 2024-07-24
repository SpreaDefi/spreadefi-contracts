// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/libraries/openzeppelin/token/SafeERC20.sol";
import "./Shared_Storage.sol";
import "src/interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol";
import "src/interfaces/external/zerolend/IPoolAddressProvider.sol";
import "src/interfaces/external/zerolend/IPool.sol";
import "src/interfaces/external/odos/IOdosRouterV2.sol";
import "src/interfaces/ILeverageNFT.sol";
import "src/interfaces/IERC721A.sol";
import "src/interfaces/ICentralRegistry.sol";
import {DataTypes} from "src/interfaces/external/zerolend/DataTypes.sol";

contract Long_Base_Odos_Zerolend is SharedStorage, IFlashLoanSimpleReceiver {
    
    using SafeERC20 for IERC20;

    enum Action {
        ADD,
        REMOVE,
        CLOSE
    }
    
    error Unauthorized();

    event debugString(string message);
    event debugBytes(string message, bytes data);
    event debugUint(string message, uint256 data);

    modifier onlyFactory() {
        _;
        address factoryAddress = ICentralRegistry(centralRegistryAddress).core("FACTORY");
        if (msg.sender != factoryAddress) revert Unauthorized();
    }

    /// @dev Modifier to restrict access to the master contract
    modifier onlyMaster() {
        address masterAddress = ICentralRegistry(centralRegistryAddress).core("MASTER");
        if (msg.sender != masterAddress) revert Unauthorized();

        _;
    }

    /// @dev Modifier to restrict access to the Zerolend pool
    modifier onlyZerolendPool() {
        address poolAddress = ICentralRegistry(centralRegistryAddress).protocols("ZEROLEND_POOL");
        if (msg.sender != poolAddress) revert Unauthorized();
        _;
    }

    /// @dev Modifier to restrict access to the contract itself
    modifier onlySelf(address _initiator) {
        if (address(this) != _initiator) revert Unauthorized();
        _;
    }

    /// @notice Initializes the strategy with the central registry address, token ID, quote token, and base token
    /// @dev This function can only be called by the factory contract
    /// @param _centralRegistry The address of the central registry contract
    /// @param _tokenId The ID of the NFT token representing the position
    /// @param _quoteToken The address of the quote token
    /// @param _baseToken The address of the base tokens
    function initialize(address _centralRegistry, uint256 _tokenId, address _quoteToken, address _baseToken) onlyFactory external {
        centralRegistryAddress = _centralRegistry;
        tokenId = _tokenId;
        QUOTE_TOKEN = _quoteToken;
        BASE_TOKEN = _baseToken;
        MARGIN_TYPE = 1;

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

    function addToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
    )
    onlyMaster external {

        IERC20(BASE_TOKEN).safeTransferFrom(msg.sender, address(this), _marginAmount);

        Action action = Action.ADD;

        bytes memory data = abi.encode(action, _marginAmount, _odosTransactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
    }

    function _addPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData,
        uint256 _totalDebt
    ) internal {

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = ICentralRegistry(centralRegistryAddress).protocols("ZEROLEND_POOL");

        IPool pool = IPool(poolAddress);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

        emit debugUint("add position called", 0);

        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(odosRouterAddress, _flashLoanAmount);

        emit debugUint("quote token allowance increased", _flashLoanAmount);
        emit debugUint("balance of quote token", IERC20(QUOTE_TOKEN).balanceOf(address(this)));

        (uint256 quoteIn, uint256 baseOut) = _swapQuoteForBase(_odosTransactionData);

        uint256 baseAmountDeposit = _marginAmount + baseOut;

        IERC20(BASE_TOKEN).safeIncreaseAllowance(poolAddress, baseAmountDeposit);

        pool.deposit(BASE_TOKEN, baseAmountDeposit, address(this), 0);

        pool.borrow(QUOTE_TOKEN, _totalDebt, 2, 0, address(this));

        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(poolAddress, _totalDebt);

    }

    function removeFromPosition(
        uint256 _baseReductionAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
    ) onlyMaster external {
            
            Action action = Action.REMOVE;
    
            bytes memory data = abi.encode(action, _baseReductionAmount, _odosTransactionData);
    
            ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
    
            address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
    
            IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
    }

    function _removePosition(
        uint256 _baseReductionAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData,
        uint256 _totalDebt
    ) internal {

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);
        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(poolAddress, _flashLoanAmount);

        pool.repay(QUOTE_TOKEN, _flashLoanAmount, 2,address(this));

        (address baseAtokenAddress,) = _getReserveData(BASE_TOKEN);

        IERC20(baseAtokenAddress).safeIncreaseAllowance(poolAddress, _baseReductionAmount);

        uint256 baseAmountUnlocked = pool.withdraw(BASE_TOKEN, _baseReductionAmount, address(this));

        emit debugUint("BASE AMOUNT UNLOCKED", baseAmountUnlocked);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

        IERC20(BASE_TOKEN).safeIncreaseAllowance(odosRouterAddress, baseAmountUnlocked);

        emit debugUint("base token allowance increased", baseAmountUnlocked);

        (uint256 baseIn, uint256 quoteOut) = _swapBaseForQuote(_odosTransactionData);

        emit debugString("done with swap");
        emit debugUint("baseIn", baseIn);
        emit debugUint("quoteOut", quoteOut);
        emit debugUint("total debt", _totalDebt);
        emit debugUint("base reduction amount", _baseReductionAmount);

        if (quoteOut > _totalDebt) {
            emit debugUint("More quote out than total debt", quoteOut);
            // re supply extra quote token to the pool
            uint256 extra = quoteOut - _totalDebt;
            IERC20(QUOTE_TOKEN).safeIncreaseAllowance(poolAddress, extra);
            pool.deposit(QUOTE_TOKEN, extra, address(this), 0);
        }
        if (baseIn < _baseReductionAmount) {
            emit debugUint("Base in is less than base reduction amount", baseIn);
            // send to user
            uint256 marginReturn = _baseReductionAmount - baseIn;
            address leverageNFTAddress = centralRegistry.core("LEVERAGE_NFT");
            IERC721A leverageNFT = IERC721A(leverageNFTAddress);
            address NFTOwner = leverageNFT.ownerOf(tokenId);
            IERC20(BASE_TOKEN).safeTransfer(NFTOwner, marginReturn);

        }




    }


    function closePosition(bytes memory _odosTransactionData) onlyMaster external {

        (, address variableDebtTokenAddress) = _getReserveData(QUOTE_TOKEN);

        uint256 debtAmount = IERC20(variableDebtTokenAddress).balanceOf(address(this));

        bytes memory data = abi.encode(Action.CLOSE, 0, debtAmount, _odosTransactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, debtAmount, data, 0);
    }

    function _closePosition(
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData,
        uint256 _totalDebt
    ) internal {

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        // 1. Repay the (QUOTE) borrowed amount to unlock collateral (BASE)
        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(poolAddress, _flashLoanAmount);

        pool.repay(QUOTE_TOKEN, _flashLoanAmount, 2, address(this));

        // 2. Withdraw the base token that was unlocked
        (address baseAtokenAddress,) = _getReserveData(BASE_TOKEN);
        // get base A token balance
        uint256 baseATokenBalance = IERC20(baseAtokenAddress).balanceOf(address(this));

        uint256 baseAmountUnlocked = pool.withdraw(BASE_TOKEN, baseATokenBalance, address(this));
        
        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

        IERC20(BASE_TOKEN).safeIncreaseAllowance(odosRouterAddress, baseAmountUnlocked);

        // 3. Swap the base token for the quote token

        (uint256 baseIn, uint256 quoteOut) = _swapBaseForQuote(_odosTransactionData);

        require (quoteOut >= _totalDebt, "Quote out is not equal to total debt");

        uint256 leftoverBase = IERC20(BASE_TOKEN).balanceOf(address(this));
        uint256 quoteBalance = IERC20(QUOTE_TOKEN).balanceOf(address(this));
        uint256 leftoverQuote = quoteBalance - _totalDebt;

        address leverageNFTAddress = centralRegistry.core("LEVERAGE_NFT");
        IERC721A leverageNFT = IERC721A(leverageNFTAddress);
        address NFTOwner = leverageNFT.ownerOf(tokenId);

        if (leftoverBase > 0) {
             
            IERC20(BASE_TOKEN).safeTransfer(NFTOwner, leftoverBase);
        }
        if (leftoverQuote > 0) {
            
            IERC20(QUOTE_TOKEN).safeTransfer(NFTOwner, leftoverQuote);
        }
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

        emit debugUint("params decoded", 0);

        if (action == Action.ADD) {

        emit debugUint("is add", 0);

            _addPosition(marginAddedOrBaseReductionAmount_, flashLoanAmount, odosTransactionData_, totalDebt);

        } else if (action == Action.REMOVE) {
            emit debugUint ("is remove", 0);
            
            _removePosition(marginAddedOrBaseReductionAmount_,flashLoanAmount, odosTransactionData_, totalDebt);
        }
            else if (action == Action.CLOSE) {
            emit debugUint ("is close", 2);
            // _closePosition(flashLoanAmount, odosTransactionData_, totalDebt);
        }

        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(msg.sender, totalDebt);

        return true;
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

}