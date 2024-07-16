// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/ERC721A/ERC721A.sol";
import "src/interfaces/ICentralRegistry.sol";


contract LeveragedNFT is ERC721A {
    
    ICentralRegistry public centralRegistry;

    mapping(uint256 => address) public tokenIdToProxy;

    modifier onlyFactory() {
        address factory = centralRegistry.protocols("FACTORY");
        require(msg.sender == factory, "LeveragedNFT: Only factory");
        _;
    }

    constructor(address _centralRegistry) ERC721A("LeveragedNFT", "LEVNFT") {
        centralRegistry = ICentralRegistry(_centralRegistry);
       
    }


    function mint(address _to, address _proxy) external onlyFactory returns (uint256 tokenId) {
        tokenId = _currentIndex;
        tokenIdToProxy[tokenId] = _proxy;
        _safeMint(_to, 1);
    }
    
}