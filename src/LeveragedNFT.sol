// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/ERC721A/ERC721A.sol";
import "src/interfaces/ICentralRegistry.sol";

/// @title LeveragedNFT Contract
/// @notice This contract implements an ERC721A token to represent leveraged positions.
/// @dev The contract interacts with the CentralRegistry to validate and manage core component addresses.
contract LeveragedNFT is ERC721A {

    /// @notice The central registry contract instance
    ICentralRegistry public centralRegistry;

    /// @notice Mapping from token ID to proxy address
    mapping(uint256 => address) public tokenIdToProxy;

    error OnlyFactory();

    /// @dev Modifier to restrict access to the factory contract
    modifier onlyFactory() {
        address factory = centralRegistry.core("FACTORY");
        if(msg.sender != factory) revert OnlyFactory();
        _;
    }


    /// @notice Constructor to set the central registry address and initialize the ERC721A token
    /// @param _centralRegistry The address of the central registry contract
    constructor(address _centralRegistry) ERC721A("LeveragedNFT", "LEVNFT") {
        centralRegistry = ICentralRegistry(_centralRegistry);
       
    }

    /// @notice Mints a new leveraged NFT
    /// @dev This function can only be called by the factory contract
    /// @param _to The address that will own the minted NFT
    /// @param _proxy The address of the proxy contract associated with the NFT
    /// @return tokenId The ID of the newly minted NFT
    function mint(address _to, address _proxy) external onlyFactory returns (uint256 tokenId) {
        tokenId = _currentIndex;
        tokenIdToProxy[tokenId] = _proxy;
        _safeMint(_to, 1);
    }
    
}