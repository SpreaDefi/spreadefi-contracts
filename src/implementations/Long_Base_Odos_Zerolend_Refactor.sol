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

contract Long_Base_Odos_Zerolend is StrategyTemplate, IFlashLoanSimpleReceiver {
    
    using SafeERC20 for IERC20;

    enum Action {
        ADD,
        REMOVE,
        CLOSE
    }

    event debugUint(string message, uint256 value);
    event debugAddress(string message, address value);

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
        POSITION_TYPE = 0;

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

    // function createAndAddToPosition(
    //     uint256 _marginAmount,
    //     uint256 _flashLoanAmount,
    //     bytes memory _odosTransactionData
    // ) override onlyMaster external {

    //     IERC20(BASE_TOKEN).safeTransferFrom(msg.sender, address(this), _marginAmount);

    //     Action action = Action.ADD;

    //     bytes memory data = abi.encode(action, _marginAmount, _odosTransactionData);

    //     ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

    //     address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

    //     IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);

    // }

    function addToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
    )
    override onlyMaster external {

        if (_flashLoanAmount > 0) {

            Action action = Action.ADD;

            bytes memory data = abi.encode(action, _marginAmount, _odosTransactionData);

            ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

            address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

            IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);

        } else {

            _addPosition(_marginAmount, _flashLoanAmount, _odosTransactionData, 0);
        }
    }

    function _addPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData,
        uint256 _totalDebt
    ) internal {

        IERC20 baseToken = IERC20(BASE_TOKEN);
        IERC20 quoteToken = IERC20(QUOTE_TOKEN);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = ICentralRegistry(centralRegistryAddress).protocols("ZEROLEND_POOL");

        IPool pool = IPool(poolAddress);

        if(_flashLoanAmount > 0) {
            address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");

            quoteToken.safeIncreaseAllowance(odosRouterAddress, _flashLoanAmount);

            (, uint256 baseOut) = _swapQuoteForBase(_odosTransactionData);

            uint256 baseAmountDeposit = _marginAmount + baseOut;

            baseToken.safeIncreaseAllowance(poolAddress, baseAmountDeposit);

            uint256 baseBalance = baseToken.balanceOf(address(this));

            emit debugUint("BASE BALANCE", baseBalance);
            emit debugAddress("THIS ADDRESS", address(this));

            pool.deposit(BASE_TOKEN, baseAmountDeposit, address(this), 0);

            pool.borrow(QUOTE_TOKEN, _totalDebt, 2, 0, address(this));

            quoteToken.safeIncreaseAllowance(poolAddress, _totalDebt);

            // return any leftover base token to the user
            uint256 leftoverBase = baseToken.balanceOf(address(this));

            // reset allowances
            quoteToken.approve(poolAddress, 0);
            quoteToken.approve(odosRouterAddress, 0);
           

            if (leftoverBase > 0) {
                baseToken.safeTransfer(_getNFTOwner(), leftoverBase);
            } 
            
        } else { // if no flash loan

            baseToken.safeIncreaseAllowance(poolAddress, _marginAmount);
            
            pool.deposit(BASE_TOKEN, _marginAmount, address(this), 0);
        }
            // reset allowances for both cases
            baseToken.approve(poolAddress, 0);
 

    }

    function removeFromPosition(
        uint256 _baseReductionAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData
    ) override onlyMaster external {
            
        if (_flashLoanAmount == 0) {

            _removePosition(_baseReductionAmount, 0, _odosTransactionData, 0);

        } else {

            Action action = Action.REMOVE;

            bytes memory data = abi.encode(action, _baseReductionAmount, _odosTransactionData);

            ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

            address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

            IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
            
        }
    }

    function _removePosition(
        uint256 _baseReductionAmount,
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData,
        uint256 _totalDebt
    ) internal {

        IERC20 quoteToken = IERC20(QUOTE_TOKEN);
        IERC20 baseToken = IERC20(BASE_TOKEN);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        if (_flashLoanAmount > 0) {
            quoteToken.safeIncreaseAllowance(poolAddress, _flashLoanAmount);

            pool.repay(QUOTE_TOKEN, _flashLoanAmount, 2,address(this));
        }

        (address baseAtokenAddress,) = _getReserveData(BASE_TOKEN);

        // IERC20(baseAtokenAddress).safeIncreaseAllowance(poolAddress, _baseReductionAmount);

        uint256 baseAmountUnlocked = pool.withdraw(BASE_TOKEN, _baseReductionAmount, address(this));

        if (_flashLoanAmount > 0) {

            address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
            
            baseToken.safeIncreaseAllowance(odosRouterAddress, baseAmountUnlocked);

            (uint256 baseIn, uint256 quoteOut) = _swapBaseForQuote(_odosTransactionData);

            if (quoteOut > _totalDebt) {
                // re supply extra quote token to the pool
                uint256 extra = quoteOut - _totalDebt;
                quoteToken.safeIncreaseAllowance(poolAddress, extra);
                pool.deposit(QUOTE_TOKEN, extra, address(this), 0);
            }

            if (baseIn < _baseReductionAmount) {
                // send to user
                uint256 marginReturn = _baseReductionAmount - baseIn;
                baseToken.safeTransfer(_getNFTOwner(), marginReturn);
            }

            baseToken.approve(odosRouterAddress, 0);

        } else {
            // send to user
            baseToken.safeTransfer(_getNFTOwner(), baseAmountUnlocked);
        }


        // reset allowances
        quoteToken.approve(poolAddress, 0);
        


    }


    function closePosition(bytes memory _odosTransactionData) override onlyMaster external {

        (, address variableDebtTokenAddress) = _getReserveData(QUOTE_TOKEN);

        uint256 debtAmount = IERC20(variableDebtTokenAddress).balanceOf(address(this));

        bytes memory data = abi.encode(Action.CLOSE, debtAmount, _odosTransactionData);

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");

        IPool(poolAddress).flashLoanSimple(address(this), QUOTE_TOKEN, debtAmount, data, 0);
    }

    function _closePosition(
        uint256 _flashLoanAmount,
        bytes memory _odosTransactionData,
        uint256 _totalDebt
    ) internal {

        address centralRegistryAddress_ = centralRegistryAddress;
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress_);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        address quoteTokenAddress = QUOTE_TOKEN;
        address baseTokenAddress = BASE_TOKEN;

        _repayClose(_flashLoanAmount, poolAddress, quoteTokenAddress);

        uint256 baseAmountUnlocked = _withdrawClose(baseTokenAddress, poolAddress);

        _swapAndSettleClose(centralRegistry, baseAmountUnlocked, _odosTransactionData, _totalDebt, baseTokenAddress, quoteTokenAddress);

    }

    function _repayClose(uint256 _flashLoanAmount, address _poolAddress, address _quoteTokenAddress ) internal {
        IPool pool = IPool(_poolAddress);
        
        IERC20 quoteToken = IERC20(_quoteTokenAddress);

        quoteToken.safeIncreaseAllowance(_poolAddress, _flashLoanAmount);

        pool.repay(_quoteTokenAddress, _flashLoanAmount, 2, address(this));

        quoteToken.approve(_poolAddress, 0);

    }

    function _withdrawClose(address _baseTokenAddress, address _poolAddress) internal returns (uint256) {
        (address baseATokenAddress, ) = _getReserveData(_baseTokenAddress);

        uint256 baseATokenBalance = IERC20(baseATokenAddress).balanceOf(address(this));

        return IPool(_poolAddress).withdraw(_baseTokenAddress, baseATokenBalance, address(this));
    }

    function _swapAndSettleClose(
        ICentralRegistry _centralRegistry, 
        uint256 _baseAmountUnlocked, 
        bytes memory _odosTransactionData, 
        uint256 _totalDebt, 
        address _baseTokenAddress, 
        address _quoteTokenAddress) internal {
            address odosRouterAddress = _centralRegistry.protocols("ODOS_ROUTER");

            IERC20 baseToken = IERC20(_baseTokenAddress);
            IERC20 quoteToken = IERC20(_quoteTokenAddress);

            baseToken.safeIncreaseAllowance(odosRouterAddress, _baseAmountUnlocked);

            (, uint256 quoteOut) = _swapBaseForQuote(_odosTransactionData);

            if(!(quoteOut >= _totalDebt)) revert NotEnoughAmountout();

            uint256 leftoverBase = baseToken.balanceOf(address(this));
            uint256 quoteBalance = quoteToken.balanceOf(address(this));
            uint256 leftoverQuote = quoteBalance - _totalDebt;

            address NFTOwner = _getNFTOwner();

            if (leftoverBase > 0) {
                baseToken.safeTransfer(NFTOwner, leftoverBase);
            }
            if (leftoverQuote > 0) {
                quoteToken.safeTransfer(NFTOwner, leftoverQuote);
            }

            baseToken.approve(odosRouterAddress, 0);

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

            _addPosition(marginAddedOrBaseReductionAmount_, flashLoanAmount, odosTransactionData_, totalDebt);

        } else if (action == Action.REMOVE) {
            
            _removePosition(marginAddedOrBaseReductionAmount_,flashLoanAmount, odosTransactionData_, totalDebt);
        }
            else if (action == Action.CLOSE) {
            _closePosition(flashLoanAmount, odosTransactionData_, totalDebt);
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

        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);

        address odosRouterAddress = centralRegistry.protocols("ODOS_ROUTER");
        (bool success, bytes memory returnData) = odosRouterAddress.call(transactionData);
        if (!success) revert SwapFailed();

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