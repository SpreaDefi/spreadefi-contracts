// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Proxy Contract
/// @notice This contract delegates all calls to an implementation contract.
/// @dev This contract uses the EVM's delegatecall to forward calls to the implementation.

// NOTE : Nice that you have used a minimal proxy but I belive there are some security considerations we are not resolving here by not using OZ Clones
// NOTE : Majorly it's the storage slot clashs which could happen here ,and I believe it's wise to use a ser Propopsed EIP for this
// NOTE : Maybe the gas cost and other factors should be looked for once as well

contract Proxy {
    /// @notice The address of the implementation contract
    address public immutable implementation;

    /// @notice Constructor to set the implementation address
    /// @param _implementation The address of the implementation contract
    constructor(address _implementation) {
        require(
            _implementation != address(0),
            "Invalid implementation address"
        );
        implementation = _implementation;
    }

    /// @notice Internal function to delegate calls to the implementation contract
    /// @dev Uses inline assembly to perform the delegatecall
    /// @param impl The address of the implementation contract
    function _delegate(address impl) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @notice Fallback function to delegate all calls to the implementation contract
    /// @dev This function will catch any call to the contract and forward it to the implementation
    fallback() external payable virtual {
        _delegate(implementation);
    }

    // NOTE: Don't need these seperately all the calls will still go to fallback if not present

    /// @notice Receive function to handle plain Ether transfers
    /// @dev This function will catch any plain Ether transfers and forward them to the implementation
    receive() external payable virtual {
        _delegate(implementation);
    }
}
