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

contract Short_Quote_Odos_Zerolend is SharedStorage {

    using SafeERC20 for IERC20;

    /// @notice Enumeration for different actions in the strategy
    enum Action {
        ADD,
        REMOVE,
        CLOSE
    }

    /// @notice Errors for the strategy contract
    error AlreadyInitialized();
    error Unauthorized();

    /// @notice Events for debugging purposes
    event debugUint(string, uint256);
    event debugAddress(string, address);
    event debugString(string);
    event debugBytes(string, bytes);

   /// @dev Modifier to restrict access to the factory contract
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

    }


    function _addPosition(
        uint256 _flashLoanAmount,
        uint256 _marginAddAmount,
        bytes memory _transactionData,
        uint256 _totalDebt
    ) internal {

        IERC20 baseToken = IERC20(BASE_TOKEN);
        IERC20 quoteToken = IERC20(QUOTE_TOKEN);

        address odosRouterAddress = ICentralRegistry(centralRegistryAddress).protocols("ODOS_ROUTER");
        address poolAddress = ICentralRegistry(centralRegistryAddress).protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);

        // Approve the base token to the odos router
        baseToken.safeIncreaseAllowance( odosRouterAddress, _flashLoanAmount);

        // swap base for quote
        (uint256 baseIn, uint256 quoteOut) = _swapBaseForQuote(_transactionData);

        uint256 quoteTotal = _marginAddAmount + quoteOut;

        // Approve the Zerolend pool to spend the quote token
        quoteToken.safeIncreaseAllowance(poolAddress, quoteTotal);

        // deposit the quote token to the Zerolend pool
        pool.deposit(QUOTE_TOKEN, quoteTotal, address(this), 0);

        // borrow base currency using quote token as collateral
        pool.borrow(BASE_TOKEN, _flashLoanAmount, 2, 0, address(this));

        // approve the quote token to the Zerolend pool
        quoteToken.safeIncreaseAllowance(poolAddress, _totalDebt);

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

        if (baseOut > _totalDebt) {
            // re supply the extra base token to the pool
            uint256 extra = baseOut - _totalDebt;
            baseToken.safeIncreaseAllowance(poolAddress, extra);

            pool.deposit(BASE_TOKEN, extra, address(this), 0);

        }
        if(quoteIn > _quoteReductionAmount) {
            // send to the user
            uint256 marginReturn = quoteIn - _quoteReductionAmount;
            address leverageNFTAddress = centralRegistry.core("LEVERAGE_NFT");
            IERC721A leverageNFT = IERC721A(leverageNFTAddress);
            address NFTOwner = leverageNFT.ownerOf(tokenId);
            quoteToken.safeTransfer(NFTOwner, marginReturn);
        }

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

        (uint256 quoteIn, uint256 baseOut) = _swapQuoteForBase(_odosTransactionData);

        uint256 leftoverQuote = baseToken.balanceOf(address(this));
        uint256 baseBalance = IERC20(BASE_TOKEN).balanceOf(address(this));
        uint256 leftoverBase = baseBalance - _totalDebt;

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

    function _getReserveData(address _asset) internal view returns (address, address){
        ICentralRegistry centralRegistry = ICentralRegistry(centralRegistryAddress);
        address poolAddress = centralRegistry.protocols("ZEROLEND_POOL");
        IPool pool = IPool(poolAddress);
        DataTypes.ReserveData memory assetData = pool.getReserveData(_asset);
        address aTokenAddress = assetData.aTokenAddress;
        address variableDebtTokenAddress = assetData.variableDebtTokenAddress;
        return (aTokenAddress, variableDebtTokenAddress);
    }



}