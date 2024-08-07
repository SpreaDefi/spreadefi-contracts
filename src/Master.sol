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
        string implementation;
        address quoteToken;
        address baseToken;
    }

    /// @notice Struct to define position parameters for modifying an existing position
    struct PositionParams {
        uint256 marginAmount;
        uint256 flashLoanAmount;
        bytes pathDefinition;
    }

    /// @dev Modifier to restrict access to the owner of the NFT
    modifier onlyNFTOwner(uint256 tokenId) {
        address leverageNFTAddress = centralRegistry.core("LEVERAGE_NFT");

        // NOTE: Follow a single method require or revert
        if (
            IERC721A(address(leverageNFTAddress)).ownerOf(tokenId) != msg.sender
        ) revert InvalidTokenOwner();
        _;
    }

    // NOTE : Create and Add position function

    // NOTE : Internal functions start with _ , good practice
    /// @notice Validates the parameters for creating a new position
    /// @dev Reverts if any of the parameters are invalid
    /// @param params The parameters for creating a new position
    function validatePositionParams(
        NewPositionParams memory params
    ) internal view returns (address) {
        address implementationAddress = centralRegistry.implementations(
            params.implementation
        );
        if (implementationAddress == address(0))
            revert ImplementationNotFound();
        if (params.quoteToken == address(0)) revert ZeroAddress();
        if (params.baseToken == address(0)) revert ZeroAddress();

        return implementationAddress;
    }

    /// @notice Creates a new leveraged position
    /// @dev Validates parameters and calls internal function to create the position
    /// @param params The parameters for creating a new position
    /// @return tokenId The ID of the newly minted leverage NFT
    /// @return proxyAddress The address of the newly created proxy contract
    function createPosition(
        NewPositionParams memory params
    ) public returns (uint256 tokenId, address proxyAddress) {
        // NOTE : a Big vulnerability I see here is allowing users to select their own Implementation name, there is not restriction in that , they could potentially access a malicious implementation or something
        address implementationAddress = validatePositionParams(params);

        (tokenId, proxyAddress) = _createPosition(
            params.quoteToken,
            params.baseToken,
            implementationAddress
        );
    }

    function _createPosition(
        address _quoteToken,
        address _baseToken,
        address _implementation
    ) internal returns (uint256 tokenId, address proxyAddress) {
        IFactory factory = IFactory(centralRegistry.core("FACTORY"));

        (tokenId, proxyAddress) = factory.createProxy(
            msg.sender,
            _implementation,
            _quoteToken,
            _baseToken
        );
    }

    /// @notice Adds to an existing leveraged position
    /// @dev Ensures the caller is the owner of the NFT before adding to the position
    /// @param _tokenId The ID of the leverage NFT
    /// @param _positionParams The parameters for adding to the position
    function addToPosition(
        uint256 _tokenId,
        PositionParams memory _positionParams
    ) public onlyNFTOwner(_tokenId) {
        emit debugString("Adding to position");
        ILeverageNFT leverageNFT = ILeverageNFT(
            centralRegistry.core("LEVERAGE_NFT")
        );

        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);

        IERC20 marginToken;
        uint256 marginAmount = _positionParams.marginAmount;

        uint256 marginType = IProxy(proxyAddress).MARGIN_TYPE();
        if (marginType == 0) {
            address quoteToken = IProxy(proxyAddress).QUOTE_TOKEN();
            marginToken = IERC20(quoteToken);
            marginToken.safeTransferFrom(
                msg.sender,
                address(this),
                marginAmount
            );
        } else if (marginType == 1) {
            address baseToken = IProxy(proxyAddress).BASE_TOKEN();
            marginToken = IERC20(baseToken);
            marginToken.safeTransferFrom(
                msg.sender,
                address(this),
                marginAmount
            );
        } else {
            revert InvalidMarginType();
        }

        // NOTE: Don't understand why transfer to master first and then proxy, could directly send it to the proxy , won't matter
        marginToken.safeIncreaseAllowance(proxyAddress, marginAmount);

        IProxy(proxyAddress).addToPosition(
            marginAmount,
            _positionParams.flashLoanAmount,
            _positionParams.pathDefinition
        );
    }

    function removeFromPosition(
        uint256 _tokenId,
        PositionParams memory params
    ) public onlyNFTOwner(_tokenId) {
        ILeverageNFT leverageNFT = ILeverageNFT(
            centralRegistry.core("LEVERAGE_NFT")
        );
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);

        IProxy(proxyAddress).removeFromPosition(
            params.marginAmount,
            params.flashLoanAmount,
            params.pathDefinition
        );
    }

    /// @notice Closes an existing leveraged position
    /// @dev Ensures the caller is the owner of the NFT before closing the position
    /// @param _tokenId The ID of the leverage NFT
    /// @param _transactionData The transaction data for closing the position
    function closePosition(
        uint256 _tokenId,
        bytes memory _transactionData
    ) public onlyNFTOwner(_tokenId) {
        ILeverageNFT leverageNFT = ILeverageNFT(
            centralRegistry.core("LEVERAGE_NFT")
        );
        address proxyAddress = leverageNFT.tokenIdToProxy(_tokenId);

        IProxy(proxyAddress).closePosition(_transactionData);
    }
}
