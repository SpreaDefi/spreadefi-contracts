// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/interfaces/ICentralRegistry.sol";
import "src/interfaces/IERC721A.sol";

abstract contract StrategyTemplate {
    /// @notice The central registry contract address
    address public centralRegistryAddress;

    /// @notice Constant representing the margin type (0 for quote, 1 for base)
    uint256 public MARGIN_TYPE;

    /// @notice The token ID representing this position
    uint256 tokenId;

    /// @notice The address of the quote token
    address public QUOTE_TOKEN;

    /// @notice The address of the base token
    address public BASE_TOKEN;

    /// @notice The position type (true for long, false for short)
    uint8 public POSITION_TYPE; 

    /// @notice Errors for the strategy contract
    error AlreadyInitialized();
    error Unauthorized();
    error NotEnoughAmountout();
    error SwapFailed();

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
    function initialize(address _centralRegistry, uint256 _tokenId, address _quoteToken, address _baseToken) virtual onlyFactory external {
        centralRegistryAddress = _centralRegistry;
        tokenId = _tokenId;
        QUOTE_TOKEN = _quoteToken;
        BASE_TOKEN = _baseToken;

    }

    function _getNFTOwner() internal view returns (address) {
        address leverageNFTAddress = ICentralRegistry(centralRegistryAddress).core("LEVERAGE_NFT");
        IERC721A leverageNFT = IERC721A(leverageNFTAddress);
        return leverageNFT.ownerOf(tokenId);
    }

    function addToPosition(
        uint256 _marginAmount,
        uint256 _flashLoanAmount,
        bytes memory _transactionData
        ) onlyMaster external virtual {}

    function removeFromPosition(
        uint256 _baseReduction, 
        uint256 _flashLoanAmount,
        bytes calldata _transactionData) onlyMaster external virtual {}

    function closePosition(bytes calldata _odosTransactionData) onlyMaster virtual external {}




}