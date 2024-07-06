// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/ERC721A/ERC721A.sol";


contract LeveragedNFT is ERC721A {

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {
    }


    function mint(address to) external returns (uint256 tokenId) {
        tokenId = _currentIndex;
        _safeMint(to, 1);
    }
    
}