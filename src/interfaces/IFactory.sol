// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function createProxy(address _to,address _implementation, address _quoteToken, address _baseToken) external returns (uint256 tokenId, address proxyAddress);
}