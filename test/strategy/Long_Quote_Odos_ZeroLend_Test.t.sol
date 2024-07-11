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

    function setUp() public {
        flashLoanMock = new FlashLoanMock();
        deal(USDCAddress, address(flashLoanMock), 1_000_000 ether, true);
        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend();

        deal(USDCAddress, (address(longQuoteOdosZerolend)), 100 ether, true);

    }

    function testSomething() public {

        longQuoteOdosZerolend.initialize(1,USDCAddress , WETHAddress, address(flashLoanMock));
        longQuoteOdosZerolend._addPosition(100 ether, 200 ether, 0.0976 ether,  )

    }

    
}