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
    error InvalidPositionType();
    error InvalidMarginType();

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
        require(IERC721A(address(leverageNFT)).ownerOf(tokenId) == msg.sender, "Master: Only NFT owner");
        _;
    }

    function createPosition(NewPositionParams memory params) public returns (uint256 tokenId, address proxyAddress) {
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

    function _createLongPosition(NewPositionParams memory params, address implementationAddress, ICentralRegistry.MarginType marginType_) 
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

    function removeFromPosition(uint256 _tokenId) onlyNFTOwner(_tokenId) public {}

    function closePosition(uint256 _tokenId) onlyNFTOwner(_tokenId) public {}
}
