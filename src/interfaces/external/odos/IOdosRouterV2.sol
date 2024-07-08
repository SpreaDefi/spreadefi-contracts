// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOdosRouterV2 {
    function swap(
        swapTokenInfo memory tokenInfo,
        bytes calldata pathDefinition,
        address executor,
        uint32 referralCode
    ) external payable returns (uint256 amountOut);

    function swapMulti(
        inputTokenInfo[] memory inputs,
        outputTokenInfo[] memory outputs,
        uint256 valueOutMin,
        bytes calldata pathDefinition,
        address executor,
        uint32 referralCode
    ) external payable returns (uint256[] memory amountsOut);

    struct swapTokenInfo {
        address inputToken;
        uint256 inputAmount;
        address inputReceiver;
        address outputToken;
        uint256 outputQuote;
        uint256 outputMin;
        address outputReceiver;
    }

    struct inputTokenInfo {
        address tokenAddress;
        uint256 amountIn;
        address receiver;
    }

    struct outputTokenInfo {
        address tokenAddress;
        uint256 relativeValue;
        address receiver;
    }
}
