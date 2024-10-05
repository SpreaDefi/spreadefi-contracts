// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

import "src/implementations/Long_Quote_Odos_Zerolend.sol";
import "src/Factory.sol";
import "src/CentralRegistry.sol";
import "src/Master.sol";
import "src/LeveragedNFT.sol";
import "src/interfaces/IMaster.sol";
import "src/interfaces/IERC721Receiver.sol";
import "src/interfaces/ILeverageNFT.sol";

contract Get_Proxy is Test {
    ILeverageNFT leveragedNFT;

    function setUp() public {
        leveragedNFT = ILeverageNFT(0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE);
    }

    function testTokenId() public {
        address proxyAddress = leveragedNFT.tokenIdToProxy(0);
        
    }


}