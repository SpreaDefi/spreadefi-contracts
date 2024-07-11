// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/interfaces/IProxy.sol";
import "src/libraries/openzeppelin/token/SafeERC20.sol";

contract FlashLoanMock {

    using SafeERC20 for IERC20;

    function flashLoanSimple(
        address initiator,
        address token,
        uint256 amount,
        bytes memory data,
        uint256 stableOrVariable // 0 = stable, 1 = variable
    ) external {

        uint256 premium = 0;

        IERC20(token).safeTransfer(initiator, amount);

        IProxy(initiator).executeOperation(token, amount, 0, initiator, data);

        IERC20(token).safeTransferFrom(initiator, address(this), amount + premium);
      
      
        
    }
    
}