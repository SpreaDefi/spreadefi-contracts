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

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    uint256 OneHundredInUSDC = 100 * 10**6;

/* ################### START OF ODOS API VARIABLES ################### */

    uint256 minAmountOut = 97336196990372768;

    // get from Odos API, call quote and then assemble, they are only valid for 60 seconds
    bytes pathDefintion = "0x83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411e1a300080159cec165660ba000c49b0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000017FA9385bE102ac3EAc297483Dd6233D62b3e1496000000000a03040b014326bec50a0100010201014c38f3630a010003020101c6ad11b20a0200040201000a0301050201034b27ca3e0a0301060701020a0301080701040a0301090a01ff0000000000000000000000000000000000000000000000000000006e9ad0b8a41e2c148e7b0385d3ecbfdb8a216a9b176211869ca2b568f2a7d4ee941e073a821ee1ffefd5ec2cc043e3bd3c840f7998cc42ee712700ba1d6cbd5ab95fcc04edde14abfa8d363adf4ead00416e3b622867aa4af98fcf0e0b871a47a80a7d7ec014414696f332c96c471634620344143325d2c0a219439258ca9da29e9cc4ce5596924745e12b931947b87d35e9f1cd53cede1ad6f7be44c12212b85afda31027c3e6a03c77a113ffc031b564abbf053aab2285ddcddad8edf438c1bab47e1a9d05a9b4000000000000000000000000000000000000000000000000";


/* ################### END OF ODOS API VARIABLES ################### */

    function setUp() public {
        flashLoanMock = new FlashLoanMock();
        deal(USDCAddress, address(flashLoanMock), 1_000_000 ether, true);
        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend();

        deal(USDCAddress, (address(this)), OneHundredInUSDC, true);
        
        longQuoteOdosZerolend.initialize(1,USDCAddress , WETHAddress, address(flashLoanMock), OdosRouterAddress);

    }

    function testSomething() public {

        console.log(address(this));

        IERC20(USDCAddress).approve(address(longQuoteOdosZerolend), OneHundredInUSDC);

        longQuoteOdosZerolend.addToPosition(OneHundredInUSDC, 2 * OneHundredInUSDC, minAmountOut, pathDefintion);

    }

    
}