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

    event debugString(string message);


    using SafeERC20 for IERC20;

    ICentralRegistry public centralRegistry;

    constructor(address _centralRegistry) {
        centralRegistry = ICentralRegistry(_centralRegistry);
    }

    struct NewPositionParams {
        address implementation;
        address quoteToken;
        address baseToken;
    }

    struct PositionParams {
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        bytes pathDefinition;
    }

    modifier onlyNFTOwner(uint256 tokenId) {
        address leverageNFTAddress = centralRegistry.core("LEVERAGE_NFT");
        if(IERC721A(address(leverageNFTAddress)).ownerOf(tokenId) != msg.sender) revert InvalidTokenOwner();
        _;
    }

    function validatePositionParams(NewPositionParams memory params) internal pure {
        if (params.implementation == address(0)) revert ImplementationNotFound();
        if (params.quoteToken == address(0)) revert ZeroAddress();
        if (params.baseToken == address(0)) revert ZeroAddress();

    }

    function createPosition(NewPositionParams memory params) public returns (uint256 tokenId, address proxyAddress) {

        validatePositionParams(params);

        (tokenId, proxyAddress) = _createPosition(params);
        
    }

    function _createPosition(NewPositionParams memory params) 
        internal returns (uint256 tokenId, address proxyAddress) 
    {
        IERC20 marginToken;
        address quoteToken = params.quoteToken;
        address baseToken = params.baseToken;
        address implementationAddress = params.implementation;
        uint256 marginType = IProxy(implementationAddress).MARGIN_TYPE();

        // 0 - QUOTE, 1 - BASE
        if (marginType == 0) {
            marginToken = IERC20(quoteToken);
        } else if (marginType == 1) {
            marginToken = IERC20(baseToken);
        } else {
            revert InvalidMarginType();
        }

        IFactory factory = IFactory(centralRegistry.core("FACTORY"));

        (tokenId, proxyAddress) = factory.createProxy(msg.sender, implementationAddress, quoteToken, baseToken);

    
    }


    function addToPosition(uint256 _tokenId, PositionParams memory _positionParams) onlyNFTOwner(_tokenId) public {
        emit debugString("Adding to position");
        ILeverageNFT leverageNFT = ILeverageNFT(centralRegistry.core("LEVERAGE_NFT"));
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);

        IERC20 marginToken;

        uint256 marginType = IProxy(proxyAddress).MARGIN_TYPE();
        if (marginType == 0) {
            address quoteToken = IProxy(proxyAddress).QUOTE_TOKEN();
            marginToken = IERC20(quoteToken);
            marginToken.safeTransferFrom(msg.sender, address(this), _positionParams.collateralAmount);
        } else if (marginType == 1) {
            address baseToken = IProxy(proxyAddress).BASE_TOKEN();
            marginToken = IERC20(baseToken);
            marginToken.safeTransferFrom(msg.sender, address(this), _positionParams.collateralAmount);
        } else {
            revert InvalidMarginType();
        }

        marginToken.safeIncreaseAllowance(proxyAddress, _positionParams.collateralAmount);

        IProxy(proxyAddress).addToPosition(_positionParams.collateralAmount, _positionParams.flashLoanAmount,_positionParams.pathDefinition);
    }

    function removeFromPosition(uint256 _tokenId, uint256 _baseReductionAmount, uint256 _flashLoanAmount, bytes memory _transactionData) onlyNFTOwner(_tokenId) public {
        ILeverageNFT leverageNFT = ILeverageNFT(centralRegistry.core("LEVERAGE_NFT"));
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);

        IProxy(proxyAddress).removeFromPosition(_baseReductionAmount, _flashLoanAmount, _transactionData);
    }

    function closePosition(uint256 _tokenId, bytes memory _transactionData) onlyNFTOwner(_tokenId) public {

        ILeverageNFT leverageNFT = ILeverageNFT(centralRegistry.core("LEVERAGE_NFT"));
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);

        IProxy(proxyAddress).closePosition(_transactionData);


    }
}
