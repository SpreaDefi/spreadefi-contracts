// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proxy.sol";
import "./interfaces/IProxy.sol";
import "./interfaces/ILeverageNFT.sol";
import "src/interfaces/ICentralRegistry.sol";


contract Factory {

    ICentralRegistry public centralRegistry;

    error unauthorized();

    modifier onlyMaster() {
        address masterAddress = centralRegistry.core("MASTER");

        if(msg.sender != masterAddress) revert();
        _;
    }

    constructor(address _centralRegistry) {
        centralRegistry = ICentralRegistry(_centralRegistry);
    }
    
    function createProxy(
        address _to, 
        address _implementation, 
        address _quoteToken, 
        address _baseToken) onlyMaster external returns(uint256 tokenId, address proxyAddress) {

        Proxy proxy = new Proxy(_implementation);

        proxyAddress = address(proxy);

        ILeverageNFT leverageNFT = ILeverageNFT(centralRegistry.core("LEVERAGE_NFT"));

        tokenId = leverageNFT.mint(_to, proxyAddress);

        IProxy(proxyAddress).initialize(tokenId, _quoteToken, _baseToken);
    }
}