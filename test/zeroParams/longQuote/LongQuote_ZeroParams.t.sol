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

contract LongQuote_ZeroParams is Test, IERC721Receiver {

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Long_Quote_Odos_Zerolend longQuoteOdosZerolend;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

    address PROXY_ADDRESS;

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411e1a3000801a64d1988eb8190028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000d0101010201ff0000000000000000000000000000000000000000005615a7b1619980f7d6b5e7f69f3dc093dfe0c95c176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000";

    bytes odosRemove = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff07254db1c224400004019b23de028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000c48622190a6b91d64ee7459c62fade9abe61b48ae5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';

    bytes odosClose = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff080132584c89e56f4d0411e00b82028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';
    
    bytes odosAddNoFlashloan = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0405f5e100078cc9dd1fe554c8028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000d0101010201ff0000000000000000000000000000000000000000005615a7b1619980f7d6b5e7f69f3dc093dfe0c95c176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';
    
    bytes odosAddNoMargin = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0401312d00071c22b523b8b0a9028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010201ff000000000000000000000000000000000000000000c48622190a6b91d64ee7459c62fade9abe61b48a176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';
    
    bytes odosRemoveNoFlashloan = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff072386f26fc1000004018188f9028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    function setUp() public {

        centralRegistry = new CentralRegistry(address(this));
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend();

        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addImplementation("LONG_QUOTE_ODOS_ZEROLEND", address(longQuoteOdosZerolend));
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);

        deal(USDCAddress, (address(this)), 200 * 10**6, true);

        IERC20(USDCAddress).approve(address(master), 200 * 10**6);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster.PositionParams memory position = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 100 * 10**6,
            flashLoanAmount: 200 * 10**6,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).createAndAddToPosition(params, position);

    }

    function testAddNoFlashloan() public {

        IMaster.PositionParams memory noFlashLoanParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 100 * 10**6,
            flashLoanAmount: 0,
            pathDefinition: odosAddNoFlashloan
        });

        IMaster(address(master)).addToPosition(0, noFlashLoanParams);

    }

    function testAddNoMargin() public {

        IMaster.PositionParams memory noMarginParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 0,
            flashLoanAmount: 20 * 10**6,
            pathDefinition: odosAddNoMargin
        });

        IMaster(address(master)).addToPosition(0, noMarginParams);

    }

    function testRemoveNoFlashloan() public {

        IMaster.PositionParams memory noFlashLoanParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 0.01 ether,
            flashLoanAmount: 0,
            pathDefinition: odosRemoveNoFlashloan
        });

        IMaster(address(master)).removeFromPosition(0, noFlashLoanParams);

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