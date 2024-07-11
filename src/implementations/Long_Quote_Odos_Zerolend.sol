// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/openzeppelin/token/SafeERC20.sol";
import "../interfaces/external/zerolend/IFlashLoanSimpleReceiver.sol";
import "../interfaces/external/zerolend/IPoolAddressProvider.sol";
import "../interfaces/external/zerolend/IPool.sol";
import "../interfaces/external/odos/IOdosRouterV2.sol";
import "../interfaces/ILeverageNFT.sol";
import {DataTypes} from "../interfaces/external/zerolend/DataTypes.sol";

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
    
    function initialize(uint256 _tokenId, address _quoteToken, address _baseToken, address _pool) external {
        if(initialized) revert AlreadyInitialized();
        tokenId = _tokenId;
        QUOTE_TOKEN = _quoteToken;
        BASE_TOKEN = _baseToken;
        initialized = true;
        pool = IPool(_pool);
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
            emit debugUint("trying to safe transfer", inputAmount);
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

        IERC20(QUOTE_TOKEN).safeTransferFrom(msg.sender, address(this), _marginAmount); // rmemove later

        bool isAdd = true;

        bytes memory data = abi.encode(isAdd, _marginAmount, _minTokenOut, _pathDefinition);

        // 1. Flash loan the _flashLoanAmount
        pool.flashLoanSimple(address(this), QUOTE_TOKEN, _flashLoanAmount, data, 0);
        
    }

    function removeFromPosition(
        uint256 _baseReduction, 
        uint256 _flashLoanAmount,
        uint256 _minTokenOut,
        bytes calldata _pathDefinition) external {

        bool isAdd = false;

        bytes memory data = abi.encode(isAdd, _baseReduction, _minTokenOut, _pathDefinition);

        // 1. Flash loan the _flashLoanAmount
        pool.flashLoanSimple(address(this), BASE_TOKEN, _flashLoanAmount, data, 0);
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
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {

        require (msg.sender == address(pool), "Caller is not the pool");
        require(initiator == address(this), "Initiator is not this contract");

        uint256 totalDebt = amount + premium;
        emit debugUint("totalDebt", totalDebt);
        
        (bool isAdd, uint256 marginOrBaseReductionAmount_, uint256 minTokenOut_, bytes memory pathDefinition_) = abi.decode(params, (bool, uint256, uint256, bytes));

        if (isAdd) {

        emit debugUint("isAdd", 0);

            _addPosition(amount, marginOrBaseReductionAmount_, minTokenOut_, pathDefinition_, totalDebt, initiator);

        } else {
            emit debugUint ("!isAdd", 0);
            
            _removePosition(amount, marginOrBaseReductionAmount_, minTokenOut_, pathDefinition_, totalDebt, initiator);
        }

        return true;
    }

    function _addPosition(
        uint256 amount,
        uint256 marginOrBaseReductionAmount_,
        uint256 minTokenOut_,
        bytes memory pathDefinition_,
        uint256 totalDebt,
        address initiator
    ) internal {
        uint256 tokenInAmount = amount + marginOrBaseReductionAmount_;
        emit debugUint("tokenInAmount", tokenInAmount);

        // 1. Swap the flash loaned (quote) amount + margin (quote) for the base token
        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), tokenInAmount);
        uint256 amountOut = _performSwap(initiator, QUOTE_TOKEN, tokenInAmount, BASE_TOKEN, minTokenOut_, minTokenOut_, pathDefinition_);

        if (amountOut > minTokenOut_) {
            uint256 extraBaseToken = amountOut - minTokenOut_;
            amountOut += extraBaseToken; // Add extra base token to the amount out
        }

        // 2. Deposit the base token to the money market
        IERC20(BASE_TOKEN).safeIncreaseAllowance(address(pool), amountOut);
        pool.supply(BASE_TOKEN, amountOut, initiator, 0);

        // 3. Borrow the money market borrow amount
        pool.borrow(BASE_TOKEN, totalDebt, 1, 0, initiator);

        IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), totalDebt);

        // Accounting
        marginAmount += marginOrBaseReductionAmount_; // amount of quote token provided as margin, does not reflect the actual margin worth. only the amount provided
        borrowAmount += amountOut; // amount of base token borrowed, does not reflect the actual borrow amount if the position is partially liquidated
    }

    function _removePosition(
        uint256 amount,
        uint256 marginOrBaseReductionAmount_,
        uint256 minTokenOut_,
        bytes memory pathDefinition_,
        uint256 totalDebt,
        address initiator
    ) internal {
        // 0. Get reserve data
        (, address quoteVariableDebtTokenAddress) = _getReserveData(QUOTE_TOKEN);
        
        // 1. Repay part of the (QUOTE) borrowed amount to unlock collateral (BASE)
        IERC20(quoteVariableDebtTokenAddress).safeIncreaseAllowance(address(pool), amount);
        pool.repay(BASE_TOKEN, amount, 1, initiator);

        // 2. Withdraw the base token that was unlocked
        (address baseAtokenAddress,) = _getReserveData(BASE_TOKEN);

        IERC20(baseAtokenAddress).safeIncreaseAllowance(address(pool), marginOrBaseReductionAmount_);
        uint256 baseAmountUnlocked = pool.withdraw(BASE_TOKEN, marginOrBaseReductionAmount_, initiator);

        // 3. Swap the unlocked base token for quote token
        IERC20(BASE_TOKEN).safeIncreaseAllowance(address(pool), baseAmountUnlocked);
        uint256 amountOut = _performSwap(initiator, BASE_TOKEN, baseAmountUnlocked, QUOTE_TOKEN, minTokenOut_, minTokenOut_, pathDefinition_);

        // 4. Approve the pool to transfer the necessary amount for the flash loan repayment
        if (amountOut > totalDebt) {
            IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), amountOut);
            uint256 remainingBalance = amountOut - totalDebt;
            IERC20(QUOTE_TOKEN).safeTransfer(msg.sender, remainingBalance);
        } else {
            IERC20(QUOTE_TOKEN).safeIncreaseAllowance(address(pool), totalDebt);
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
