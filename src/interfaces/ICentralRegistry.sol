// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICentralRegistry.sol";

interface ICentralRegistry {
    function implementations(string calldata) external view returns (address);

    function protocols(string calldata) external view returns (address);

    function core(string calldata) external view returns (address);

    struct Implementation {
        address implementation;
        PositionType positionType;
        MarginType marginType;
    }

    enum PositionType {
        LONG,
        SHORT
    }

    enum MarginType {
        QUOTE,
        BASE
    }


}