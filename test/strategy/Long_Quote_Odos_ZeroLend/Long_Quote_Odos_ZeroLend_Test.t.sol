// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

import "src/implementations/Long_Quote_Odos_Zerolend.sol";
import "test/Mocks/FlashLoanMock.sol";

contract Long_Quote_Odos_ZeroLend_Test is Test {
    Long_Quote_Odos_Zerolend longQuoteOdosZerolend;
    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    uint256 OneHundredInUSDC = 100 * 10**6;

    uint256 FiftyInUSDC = 50 * 10**6;

/* ################### START OF ODOS API VARIABLES ################### */

    // get from Odos API, call quote and then assemble, they are only valid for 60 seconds
    bytes public odosAddData = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411e1a30008013fc468540fa8b0028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000015615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f0000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000";

    bytes public odosRemoveData = hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff0738d7ea4c68000004032d72d2028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000015615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f0000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000";
    event debugBytes(string, bytes);

/* ################### END OF ODOS API VARIABLES ################### */

    function setUp() public {

        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend();

        console.log("longQuoteOdosZerolend address: ", address(longQuoteOdosZerolend));

        deal(USDCAddress, (address(this)), OneHundredInUSDC, true);
        
        longQuoteOdosZerolend.initialize(1,USDCAddress , WETHAddress, address(zeroLendAddress), OdosRouterAddress);

    }

    function testAdd() public {

        console.log(address(this));

        IERC20(USDCAddress).approve(address(longQuoteOdosZerolend), OneHundredInUSDC);

        longQuoteOdosZerolend.addToPosition(OneHundredInUSDC, 2 * OneHundredInUSDC, odosAddData);

        console.log("Margin Amount: ", longQuoteOdosZerolend.marginAmount());
        console.log("Borrow Amount: ", longQuoteOdosZerolend.borrowAmount());

    }
    // lower exposure, flash loan amount slightly less than the price of the base removal amount
    function testLowerExposure() public {

        console.log(address(this));

        IERC20(USDCAddress).approve(address(longQuoteOdosZerolend), OneHundredInUSDC);

        longQuoteOdosZerolend.addToPosition(OneHundredInUSDC, 2 * OneHundredInUSDC, odosAddData);

        uint256 baseReduction = 0.016 ether;
        uint256 flashLoanAmount = 53260870; // price of 0.015 WETH in USDC

        longQuoteOdosZerolend.removeFromPosition(baseReduction, flashLoanAmount, odosRemoveData);
        

    }

    
}