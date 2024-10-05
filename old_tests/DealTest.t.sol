// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

contract testingLinea is Test {

    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    function setUp() public {

    }

    function testGiveThisWETH() public {

        deal(WETHAddress, (address(this)), 10**18, false);
         
    }
}