// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/interfaces/IProxy.sol";
import "src/libraries/openzeppelin/token/SafeERC20.sol";

contract FlashLoanMock {

    using SafeERC20 for IERC20;

    event debugUint(string, uint256);
    event debugAddress(string, address);

    function flashLoanSimple(
        address initiator,
        address token,
        uint256 amount,
        bytes calldata data,
        uint16 stableOrVariable // 0 = stable, 1 = variable
    ) external {
        emit debugAddress("initiator", initiator);
        emit debugAddress("token", token);
        emit debugUint("amount", amount);
        emit debugUint("stableOrVariable", stableOrVariable);

        uint256 premium = 0;

        IERC20(token).safeTransfer(initiator, amount);
        emit debugUint("Safe transfer done", 0);

        IProxy(initiator).executeOperation(token, amount, 0, initiator, data);

        IERC20(token).safeTransferFrom(initiator, address(this), amount + premium);
      
      
        
    }
    
}