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

contract Using_Proxy_Long_Quote_Odos_ZeroLend_Test is Test, IERC721Receiver {

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Long_Quote_Odos_Zerolend longQuoteOdosZerolend;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411e1a300080132ea28589ac2b0028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000015615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f0000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000";


    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    function setUp() public {

        centralRegistry = new CentralRegistry();
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend(address(centralRegistry));

        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addImplementation("LONG_QUOTE_ODOS_ZEROLEND", address(longQuoteOdosZerolend));
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);

        address zeroLendPool = centralRegistry.protocols("ZEROLEND_POOL");
        console.log("central registry address: %s", address(centralRegistry));
        console.log("longQuoteOdosZerolend address: %s", address(longQuoteOdosZerolend));
    }

    function testCreatePosition() public {
        
        deal(USDCAddress, (address(this)), 100 * 10**6, true);

        IERC20(USDCAddress).approve(address(master), 100 * 10**6);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: address(longQuoteOdosZerolend),
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        IMaster.PositionParams memory position = IMaster.PositionParams({
            collateralAmount: 100 * 10**6,
            flashLoanAmount: 200 * 10**6,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).addToPosition(0, position);

    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Here you can add your custom logic if needed
        return this.onERC721Received.selector;
    }




}