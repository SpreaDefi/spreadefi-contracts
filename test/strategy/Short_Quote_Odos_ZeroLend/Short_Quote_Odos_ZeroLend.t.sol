// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

import "src/implementations/Short_Quote_Odos_Zerolend.sol";
import "src/Factory.sol";
import "src/CentralRegistry.sol";
import "src/Master.sol";
import "src/LeveragedNFT.sol";
import "src/interfaces/IMaster.sol";
import "src/interfaces/IERC721Receiver.sol";

contract Using_Proxy_Short_Quote_Odos_ZeroLend_Test is Test, IERC721Receiver {

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Short_Quote_Odos_Zerolend shortQuoteOdosZerolend;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;
    
    error debugString(string message);

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff07d8b72d434c8000040c0f478d028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000";

    bytes odosRemove = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0402faf08007358e504d0c9a62028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010201ff000000000000000000000000000000000000000000416e3b622867aa4af98fcf0e0b871a47a80a7d7e176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';

    bytes odosClose = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f040c1988c007d97f7655498220028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';
    
    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    function setUp() public {
        centralRegistry = new CentralRegistry(address(this));
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        shortQuoteOdosZerolend = new Short_Quote_Odos_Zerolend();

        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addImplementation("SHORT_QUOTE_ODOS_ZEROLEND", address(shortQuoteOdosZerolend));
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);
    }

    function testCreatePosition() public {
        deal(USDCAddress, (address(this)), 100 * 10**6, true);

        IERC20(USDCAddress).approve(address(master), 100 * 10**6);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "SHORT_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmount: 100 * 10**6,
            flashLoanAmount: 0.061 ether,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).addToPosition(
            0,
            positionParams
        );


    }

    function testRemovePosition() public {
        deal(USDCAddress, (address(this)), 100 * 10**6, true);

        IERC20(USDCAddress).approve(address(master), 100 * 10**6);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "SHORT_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmount: 100 * 10**6,
            flashLoanAmount: 0.061 ether,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).addToPosition(
            0,
            positionParams
        );

        // reduce exposure, can unwind by inputting margin amount and flash loan amount as leveraged ratio
        IMaster.PositionParams memory removeParams = IMaster.PositionParams({
            marginAmount: 50 * 10**6,
            flashLoanAmount: 0.015 ether,
            pathDefinition: odosRemove
        });

        IMaster(address(master)).removeFromPosition(
            0,
            removeParams
        );


    }

    function testClose() public {

        console.log("testing close");
        deal(USDCAddress, (address(this)), 100 * 10**6, true);

        IERC20(USDCAddress).approve(address(master), 100 * 10**6);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "SHORT_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmount: 100 * 10**6,
            flashLoanAmount: 0.061 ether,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).addToPosition(
            0,
            positionParams
        );

        master.closePosition(0, odosClose);



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