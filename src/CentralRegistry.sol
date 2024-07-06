// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMaster.sol";

contract CentralRegistry {

    struct Implementation {
        address implementation;
        IMaster.PositionType positionType;
        IMaster.MarginType marginType;
    }
    
    mapping(string => Implementation) public implementations;

    function addImplementation(string calldata _name, Implementation calldata _implementation) public {
        implementations[_name] = _implementation;
    }

    function removeImplementation(string calldata _name) public {
        delete implementations[_name];
    }
}