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

contract ShortQuote_ZeroParams is Test, IERC721Receiver {

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

    event debugAddress(string message, address addr);

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff078e1bc9bf040000040602f49f028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000";

    bytes odosRemove = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f040175fe30072006b932ff127c028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';

    bytes odosClose = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f040c6dc9db080110ee367fe8e6d0028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010201ff0000000000000000000000000000000000000000007077f0cff76077d0ebb335b607db574400510557176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';
    
    bytes odosAddNoMargin = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff070e35fa931a0000039a2395028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';

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

        deal(USDCAddress, (address(this)), 200 * 10**6, true);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "SHORT_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 100 * 10**6,
            flashLoanAmount: 40000000000000000,
            pathDefinition: odosAdd
        });

        IERC20(USDCAddress).approve(address(master), 200 * 10**6);

        IMaster(address(master)).createAndAddToPosition(
            params,
            positionParams
        );
    }

    function testAddWithNoFlashloan() public {

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 100 * 10**6,
            flashLoanAmount: 0,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).addToPosition(0, positionParams);


    }

    function testAddWithNoMargin() public {

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 0,
            flashLoanAmount: 4000000000000000,
            pathDefinition: odosAddNoMargin
        });

        IMaster(address(master)).addToPosition(0, positionParams);
        
    }

    function testRemoveWithNoFlashloan() public {

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 10 * 10**6,
            flashLoanAmount: 0,
            pathDefinition: odosRemove
        });

        IMaster(address(master)).removeFromPosition(0, positionParams);
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