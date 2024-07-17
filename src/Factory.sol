// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proxy.sol";
import "./interfaces/IProxy.sol";
import "./interfaces/ILeverageNFT.sol";
import "src/interfaces/ICentralRegistry.sol";

/// @title Factory Contract
/// @notice This contract is responsible for creating proxy contracts and minting leverage NFTs.
/// @dev Uses the CentralRegistry to obtain addresses of core components.

contract Factory {

     /// @notice The central registry contract instance
    ICentralRegistry public centralRegistry;

    /// @notice Error for unauthorized access
    error unauthorized();

    /// @dev Modifier to restrict access to the master contract
    modifier onlyMaster() {
        address masterAddress = centralRegistry.core("MASTER");

        if(msg.sender != masterAddress) revert();
        _;
    }

    /// @notice Constructor to set the central registry address
    /// @param _centralRegistry The address of the central registry contract
    constructor(address _centralRegistry) {
        centralRegistry = ICentralRegistry(_centralRegistry);
    }
    
    /// @notice Creates a new proxy contract and mints a leverage NFT
    /// @dev This function can only be called by the master contract
    /// @param _to The address that will own the leverage NFT
    /// @param _implementation The address of the implementation contract
    /// @param _quoteToken The address of the quote token
    /// @param _baseToken The address of the base token
    /// @return tokenId The ID of the newly minted leverage NFT
    /// @return proxyAddress The address of the newly created proxy contract
    function createProxy(
        address _to, 
        address _implementation, 
        address _quoteToken, 
        address _baseToken) onlyMaster external returns(uint256 tokenId, address proxyAddress) {

        Proxy proxy = new Proxy(_implementation);

        proxyAddress = address(proxy);

        ILeverageNFT leverageNFT = ILeverageNFT(centralRegistry.core("LEVERAGE_NFT"));

        tokenId = leverageNFT.mint(_to, proxyAddress);

        IProxy(proxyAddress).initialize(address(centralRegistry), tokenId, _quoteToken, _baseToken);
    }
}