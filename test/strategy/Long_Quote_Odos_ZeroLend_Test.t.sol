// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

import "src/implementations/Long_Quote_Odos_Zerolend.sol";
import "test/Mocks/FlashLoanMock.sol";

contract Long_Quote_Odos_ZeroLend_Test is Test {
    Long_Quote_Odos_Zerolend longQuoteOdosZerolend;
    FlashLoanMock flashLoanMock;
    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    uint256 OneHundredInUSDC = 100 * 10**6;

/* ################### START OF ODOS API VARIABLES ################### */

    // get from Odos API, call quote and then assemble, they are only valid for 60 seconds
    bytes pathDefintion = "0x83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411e1a300080153cc7d3a81eb3000c49b0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000017FA9385bE102ac3EAc297483Dd6233D62b3e14960000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000";

    uint256 minAmountOut = 95644855329483568;

/* ################### END OF ODOS API VARIABLES ################### */

    function setUp() public {
        flashLoanMock = new FlashLoanMock();
        deal(USDCAddress, address(flashLoanMock), 1_000_000 ether, true);
        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend();

        deal(USDCAddress, (address(this)), OneHundredInUSDC, true);
        
        longQuoteOdosZerolend.initialize(1,USDCAddress , WETHAddress, address(flashLoanMock));

    }

    function testSomething() public {

        console.log(address(this));

        IERC20(USDCAddress).approve(address(longQuoteOdosZerolend), OneHundredInUSDC);

        longQuoteOdosZerolend.addToPosition(OneHundredInUSDC, 2 * OneHundredInUSDC, minAmountOut, pathDefintion);

    }

    
}