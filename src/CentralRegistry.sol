// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMaster.sol";

contract CentralRegistry {

    address public admin;

    mapping(string => address) public implementations;
    mapping(string => address) public protocols;
    mapping(string => address) public core;

    modifier onlyAdmin() {
        require(msg.sender == admin, "CentralRegistry: Only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }
    

    function addImplementation(string calldata _name, address _implementation) public onlyAdmin {
        implementations[_name] = _implementation;
    }

    function removeImplementation(string calldata _name) public onlyAdmin {
        delete implementations[_name];
    }

    function addProtocol(string calldata _name, address _protocol) public onlyAdmin {
        protocols[_name] = _protocol;
    }

    function addCore(string calldata _name, address _core) public onlyAdmin {
        core[_name] = _core;
    }
}