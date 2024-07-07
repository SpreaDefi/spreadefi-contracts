// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILeverageNFT {

     function mint(address to, address _proxy) external returns (uint256 tokenId);

     function tokenIdToProxy(uint256 tokenId) external view returns (address proxy);
}