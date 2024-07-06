// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/openzeppelin/token/SafeERC20.sol";
import "./interfaces/ICentralRegistry.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IProxy.sol";
import "./LeveragedNFT.sol";
import "./interfaces/IFactory.sol";

contract Master {

    error ImplementationNotFound();
    error InvalidPositionType();
    error InvalidMarginType();

    using SafeERC20 for IERC20;

    ICentralRegistry public centralRegistry;
    IFactory public factory;

    enum PositionType {
        LONG,
        SHORT
    }

    enum MarginType {
        QUOTE,
        BASE
    }

    constructor() {}

    struct PositionParams {
        string implementation;
        address quoteToken;
        address baseToken;
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        uint256 minTokenOut;
        uint256 moneyMarketBorrowAmount;
    }

    function createPosition(PositionParams memory params) public returns (uint256 tokenId, address proxyAddress) {
        ICentralRegistry.Implementation memory implementation_ = centralRegistry.implementations(params.implementation);
        address implementationAddress = implementation_.implementation;
        ICentralRegistry.PositionType positionType_ = implementation_.positionType;
        ICentralRegistry.MarginType marginType_ = implementation_.marginType;

        if (implementationAddress == address(0)) revert ImplementationNotFound();

        if (positionType_ == ICentralRegistry.PositionType.LONG) {  
            (tokenId, proxyAddress) = _createLongPosition(params, implementationAddress, marginType_);
        } else if (positionType_ == ICentralRegistry.PositionType.SHORT) {
        
        } else {
            revert InvalidPositionType();
        }
    }

    function _createLongPosition(PositionParams memory params, address implementationAddress, ICentralRegistry.MarginType marginType_) 
        internal returns (uint256 tokenId, address proxyAddress) 
    {
        IERC20 quoteToken = IERC20(params.quoteToken);
        IERC20 baseToken = IERC20(params.baseToken);

        if (marginType_ == ICentralRegistry.MarginType.QUOTE) {
            quoteToken.safeTransferFrom(msg.sender, address(this), params.collateralAmount);

            (tokenId, proxyAddress) = factory.createProxy(msg.sender, implementationAddress, params.quoteToken, params.baseToken);

            quoteToken.safeIncreaseAllowance(proxyAddress, params.collateralAmount);

            IProxy(proxyAddress).addToPosition(params.collateralAmount, params.flashLoanAmount, params.minTokenOut, params.moneyMarketBorrowAmount);

        } else if (marginType_ == ICentralRegistry.MarginType.BASE) {

            baseToken.safeTransferFrom(msg.sender, address(this), params.collateralAmount);

            (tokenId, proxyAddress) = factory.createProxy(msg.sender, implementationAddress, params.quoteToken, params.baseToken);

            baseToken.safeIncreaseAllowance(proxyAddress, params.collateralAmount);

            IProxy(proxyAddress).addToPosition(params.collateralAmount, params.flashLoanAmount, params.minTokenOut, params.moneyMarketBorrowAmount);
            
        } else {
            revert InvalidMarginType();
        }
    }

    function addToPosition(uint256 _tokenId) public {}

    function removeFromPosition(uint256 _tokenId) public {}

    function closePosition(uint256 _tokenId) public {}
}
