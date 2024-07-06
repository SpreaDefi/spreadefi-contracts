// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICentralRegistry.sol";
import "../interfaces/IMaster.sol";

interface ICentralRegistry {
    function implementations(string calldata) external view returns (ICentralRegistry.Implementation memory);

    struct Implementation {
        address implementation;
        IMaster.PositionType positionType;
        IMaster.MarginType marginType;
    }

    
}