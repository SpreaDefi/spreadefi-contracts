// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMaster.sol";

contract CentralRegistry {

    address public admin;

    struct Implementation {
        address implementation;
        IMaster.PositionType positionType;
        IMaster.MarginType marginType;
    }

    mapping(string => Implementation) public implementations;

    modifier onlyAdmin() {
        require(msg.sender == admin, "CentralRegistry: Only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }
    

    function addImplementation(string calldata _name, Implementation calldata _implementation) public onlyAdmin {
        implementations[_name] = _implementation;
    }

    function removeImplementation(string calldata _name) public onlyAdmin {
        delete implementations[_name];
    }
}