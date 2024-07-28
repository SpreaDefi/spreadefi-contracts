// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

contract testingLinea is Test {

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;

    function setUp() public {

    }

    function testGiveThisUSDC() public {

        deal(USDCAddress, (address(this)), 10**8, true);
        deal(USDCAddress, (address(this)), 10**8, true);
         
    }
}