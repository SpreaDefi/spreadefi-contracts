// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proxy.sol";
import "./interfaces/IProxy.sol";
import "./interfaces/ILeverageNFT.sol";

contract Factory {

    ILeverageNFT public leverageNFT;
    
    function createProxy(
        address _to, 
        address _implementation, 
        address _quoteToken, 
        address _baseToken) external returns(uint256 tokenId, address proxyAddress) {

        Proxy proxy = new Proxy(_implementation);

        proxyAddress = address(proxy);

        tokenId = leverageNFT.mint(_to, proxyAddress);

        IProxy(proxyAddress).initialize(_quoteToken, _baseToken);
    }
}