// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
    address public immutable implementation;

    constructor(address _implementation) {
        require(_implementation != address(0), "Invalid implementation address");
        implementation = _implementation;
    }

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

    fallback() external payable virtual {
        _delegate(implementation);
    }

    receive() external payable virtual {
        _delegate(implementation);
    }
}
