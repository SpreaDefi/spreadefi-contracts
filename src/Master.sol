// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/openzeppelin/token/SafeERC20.sol";
import "./interfaces/ICentralRegistry.sol";
import "./interfaces/IMaster.sol";
import "./interfaces/IProxy.sol";
import "./interfaces/ILeverageNFT.sol";
import "./interfaces/IERC721A.sol";
import "./LeveragedNFT.sol";
import "./interfaces/IFactory.sol";

contract Master {

    error ImplementationNotFound();
    error InvalidMarginType();
    error InvalidTokenId();
    error InvalidTokenOwner();
    error ZeroAddress();
    error ZeroAmount();


    using SafeERC20 for IERC20;

    ICentralRegistry public centralRegistry;
    IFactory public factory;
    ILeverageNFT public leverageNFT;

    constructor(address _centralRegistry, address _factory, address _leverageNFT) {
        centralRegistry = ICentralRegistry(_centralRegistry);
        factory = IFactory(_factory);
        leverageNFT = ILeverageNFT(_leverageNFT);
    }

    struct NewPositionParams {
        string implementation;
        address quoteToken;
        address baseToken;
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        uint256 minTokenOut;
        uint256 moneyMarketBorrowAmount;
    }

    struct PositionParams {
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        uint256 minTokenOut;
        uint256 moneyMarketBorrowAmount;
    }

    modifier onlyNFTOwner(uint256 tokenId) {
        if(IERC721A(address(leverageNFT)).ownerOf(tokenId) != msg.sender) revert InvalidTokenOwner();
        _;
    }

    function validatePositionParams(NewPositionParams memory params, address _implementation) internal pure {
        if (_implementation == address(0)) revert ImplementationNotFound();
        if (params.quoteToken == address(0)) revert ZeroAddress();
        if (params.baseToken == address(0)) revert ZeroAddress();
        if (params.collateralAmount == 0) revert ZeroAmount();
        if (params.flashLoanAmount == 0) revert ZeroAmount();
        if (params.minTokenOut == 0) revert ZeroAmount();
        if (params.moneyMarketBorrowAmount == 0) revert ZeroAmount();

    }

    function createPosition(NewPositionParams memory params) public returns (uint256 tokenId, address proxyAddress) {
        ICentralRegistry.Implementation memory implementation_ = centralRegistry.implementations(params.implementation);
        address implementationAddress = implementation_.implementation;
        validatePositionParams(params, implementationAddress);
        ICentralRegistry.MarginType marginType_ = implementation_.marginType;

        (tokenId, proxyAddress) = _createPosition(params, implementationAddress, marginType_);
        
    }

    function _createPosition(NewPositionParams memory params, address implementationAddress, ICentralRegistry.MarginType marginType_) 
        internal returns (uint256 tokenId, address proxyAddress) 
    {
        IERC20 marginToken;
        address quoteToken = params.quoteToken;
        address baseToken = params.baseToken;
        uint256 collateralAmount = params.collateralAmount;

        if (marginType_ == ICentralRegistry.MarginType.QUOTE) {
            marginToken = IERC20(quoteToken);
        } else if (marginType_ == ICentralRegistry.MarginType.BASE) {
            marginToken = IERC20(baseToken);
        } else {
            revert InvalidMarginType();
        }

        marginToken.safeTransferFrom(msg.sender, address(this), collateralAmount);

        (tokenId, proxyAddress) = factory.createProxy(msg.sender, implementationAddress, quoteToken, baseToken);

        marginToken.safeIncreaseAllowance(proxyAddress, collateralAmount);

        IProxy(proxyAddress).addToPosition(collateralAmount, params.flashLoanAmount, params.minTokenOut, params.moneyMarketBorrowAmount);
    }


    function addToPosition(uint256 _tokenId, PositionParams memory _positionParams) onlyNFTOwner(_tokenId) public {
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);
        IProxy(proxyAddress).addToPosition(_positionParams.collateralAmount, _positionParams.flashLoanAmount, _positionParams.minTokenOut, _positionParams.moneyMarketBorrowAmount);
    }

    function removeFromPosition(uint256 _tokenId) onlyNFTOwner(_tokenId) public {

    }

    function closePosition(uint256 _tokenId) onlyNFTOwner(_tokenId) public {}
}
