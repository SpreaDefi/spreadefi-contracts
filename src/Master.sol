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

/// @title Master Contract
/// @notice This contract is the main entry point for users of the protocol to create, manage, and close leveraged positions.
/// @dev Interacts with the CentralRegistry, Factory, LeveragedNFT, and Proxy contracts to handle leveraged positions.
contract Master {

    using SafeERC20 for IERC20;

    /// @notice The central registry contract instance
    ICentralRegistry public centralRegistry;

    /// @notice Errors related to the Master contract operations
    error ImplementationNotFound();
    error InvalidMarginType();
    error InvalidTokenId();
    error InvalidTokenOwner();
    error ZeroAddress();
    error ZeroAmount();

    /// @notice Event for debugging purposes
    event debugString(string message);

    /// @notice Constructor to set the central registry address
    /// @param _centralRegistry The address of the central registry contract
    constructor(address _centralRegistry) {
        centralRegistry = ICentralRegistry(_centralRegistry);
    }

    /// @notice Struct to define new position parameters
    struct NewPositionParams {
        address implementation;
        address quoteToken;
        address baseToken;
    }

    /// @notice Struct to define position parameters for modifying an existing position
    struct PositionParams {
        uint256 collateralAmount;
        uint256 flashLoanAmount;
        bytes pathDefinition;
    }

    /// @dev Modifier to restrict access to the owner of the NFT
    modifier onlyNFTOwner(uint256 tokenId) {
        address leverageNFTAddress = centralRegistry.core("LEVERAGE_NFT");
        if(IERC721A(address(leverageNFTAddress)).ownerOf(tokenId) != msg.sender) revert InvalidTokenOwner();
        _;
    }

    /// @notice Validates the parameters for creating a new position
    /// @dev Reverts if any of the parameters are invalid
    /// @param params The parameters for creating a new position
    function validatePositionParams(NewPositionParams memory params) internal pure {
        if (params.implementation == address(0)) revert ImplementationNotFound();
        if (params.quoteToken == address(0)) revert ZeroAddress();
        if (params.baseToken == address(0)) revert ZeroAddress();

    }

    /// @notice Creates a new leveraged position
    /// @dev Validates parameters and calls internal function to create the position
    /// @param params The parameters for creating a new position
    /// @return tokenId The ID of the newly minted leverage NFT
    /// @return proxyAddress The address of the newly created proxy contract
    function createPosition(NewPositionParams memory params) public returns (uint256 tokenId, address proxyAddress) {

        validatePositionParams(params);

        (tokenId, proxyAddress) = _createPosition(params);
        
    }

    /// @notice Internal function to create a new leveraged position
    /// @dev Mints an NFT and initializes a proxy contract for the position
    /// @param params The parameters for creating a new position
    /// @return tokenId The ID of the newly minted leverage NFT
    /// @return proxyAddress The address of the newly created proxy contract
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

    /// @notice Adds to an existing leveraged position
    /// @dev Ensures the caller is the owner of the NFT before adding to the position
    /// @param _tokenId The ID of the leverage NFT
    /// @param _positionParams The parameters for adding to the position
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

    /// @notice Removes from an existing leveraged position
    /// @dev Ensures the caller is the owner of the NFT before removing from the position
    /// @param _tokenId The ID of the leverage NFT
    /// @param _baseReductionAmount The amount of base token to reduce
    /// @param _flashLoanAmount The amount of flash loan to use
    /// @param _transactionData The transaction data for the removal
    function removeFromPosition(uint256 _tokenId, uint256 _baseReductionAmount, uint256 _flashLoanAmount, bytes memory _transactionData) onlyNFTOwner(_tokenId) public {
        ILeverageNFT leverageNFT = ILeverageNFT(centralRegistry.core("LEVERAGE_NFT"));
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);

        IProxy(proxyAddress).removeFromPosition(_baseReductionAmount, _flashLoanAmount, _transactionData);
    }

    /// @notice Closes an existing leveraged position
    /// @dev Ensures the caller is the owner of the NFT before closing the position
    /// @param _tokenId The ID of the leverage NFT
    /// @param _transactionData The transaction data for closing the position
    function closePosition(uint256 _tokenId, bytes memory _transactionData) onlyNFTOwner(_tokenId) public {

        ILeverageNFT leverageNFT = ILeverageNFT(centralRegistry.core("LEVERAGE_NFT"));
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);

        IProxy(proxyAddress).closePosition(_transactionData);


    }
}
