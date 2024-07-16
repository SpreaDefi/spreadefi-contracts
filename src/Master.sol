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

    constructor(address _centralRegistry) {
        centralRegistry = ICentralRegistry(_centralRegistry);
    }

    struct NewPositionParams {
        address implementation;
        address quoteToken;
        address baseToken;
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        uint256 minTokenOut;
        bytes pathDefinition;
    }

    struct PositionParams {
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        uint256 minTokenOut;
        bytes pathDefinition;
    }

    modifier onlyNFTOwner(uint256 tokenId) {
        address leverageNFTAddress = centralRegistry.protocols("LEVERAGE_NFT");
        if(IERC721A(address(leverageNFTAddress)).ownerOf(tokenId) != msg.sender) revert InvalidTokenOwner();
        _;
    }

    function validatePositionParams(NewPositionParams memory params) internal pure {
        if (params.implementation == address(0)) revert ImplementationNotFound();
        if (params.quoteToken == address(0)) revert ZeroAddress();
        if (params.baseToken == address(0)) revert ZeroAddress();
        if (params.collateralAmount == 0) revert ZeroAmount();
        if (params.flashLoanAmount == 0) revert ZeroAmount();
        if (params.minTokenOut == 0) revert ZeroAmount();

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
        uint256 collateralAmount = params.collateralAmount;
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

        marginToken.safeTransferFrom(msg.sender, address(this), collateralAmount);

        IFactory factory = IFactory(centralRegistry.protocols("FACTORY"));

        (tokenId, proxyAddress) = factory.createProxy(msg.sender, implementationAddress, quoteToken, baseToken);

        marginToken.safeIncreaseAllowance(proxyAddress, collateralAmount);

        // marginToken.safeIncreaseAllowance(proxyAddress, collateralAmount);

        // IProxy(proxyAddress).addToPosition(collateralAmount, params.flashLoanAmount, params.minTokenOut, params.pathDefinition);
    
    }


    function addToPosition(uint256 _tokenId, PositionParams memory _positionParams) onlyNFTOwner(_tokenId) public {
        ILeverageNFT leverageNFT = ILeverageNFT(centralRegistry.protocols("LEVERAGE_NFT"));
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);
        IProxy(proxyAddress).addToPosition(_positionParams.collateralAmount, _positionParams.flashLoanAmount, _positionParams.minTokenOut, _positionParams.pathDefinition);
    }

    function removeFromPosition(uint256 _tokenId) onlyNFTOwner(_tokenId) public {

    }

    function closePosition(uint256 _tokenId) onlyNFTOwner(_tokenId) public {}
}
