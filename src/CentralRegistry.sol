// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMaster.sol";

/// @title Central Registry
/// @notice This contract manages implementations, protocols, and core addresses.
/// @dev This contract uses mappings to store addresses related to different components of the system.

contract CentralRegistry {

    /// @notice Address of the admin
    address public admin;

    /// @notice Mapping of implementation names to their addresses
    mapping(string => address) public implementations;

     /// @notice Mapping of protocol names to their addresses
    mapping(string => address) public protocols;

    /// @notice Mapping of core component names to their addresses
    mapping(string => address) public core;

    error OnlyAdmin();

    /// @dev Modifier to restrict access to only the admin
    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;
    }

    /// @notice Constructor to set the initial admin of the contract
    constructor(address _admin) {
        admin = _admin;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }
    
    /// @notice Adds an implementation address to the registry
    /// @param _name The name of the implementation
    /// @param _implementation The address of the implementation
    function addImplementation(string calldata _name, address _implementation) public onlyAdmin {
        implementations[_name] = _implementation;
    }

    /// @notice Adds a protocol address to the registry
    /// @param _name The name of the protocol
    /// @param _protocol The address of the protocol
    function addProtocol(string calldata _name, address _protocol) public onlyAdmin {
        protocols[_name] = _protocol;
    }

    /// @notice Adds a core component address to the registry
    /// @param _name The name of the core component
    /// @param _core The address of the core component
    function addCore(string calldata _name, address _core) public onlyAdmin {
        core[_name] = _core;
    }
}