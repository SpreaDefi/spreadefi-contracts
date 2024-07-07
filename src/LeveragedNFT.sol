// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/ERC721A/ERC721A.sol";


contract LeveragedNFT is ERC721A {
    
    address public factory;

    mapping(uint256 => address) public tokenIdToProxy;

    modifier onlyFactory() {
        require(msg.sender == factory, "LeveragedNFT: Only factory");
        _;
    }

    constructor(string memory name_, string memory symbol_, address _factory) ERC721A(name_, symbol_) {
        factory = _factory;
    }


    function mint(address _to, address _proxy) external onlyFactory returns (uint256 tokenId) {
        tokenId = _currentIndex;
        tokenIdToProxy[tokenId] = _proxy;
        _safeMint(_to, 1);
    }
    
}