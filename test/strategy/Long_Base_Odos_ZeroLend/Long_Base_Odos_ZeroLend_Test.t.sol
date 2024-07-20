// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

import "src/implementations/Long_Quote_Odos_Zerolend.sol";
import "src/implementations/Long_Base_Odos_Zerolend.sol";
import "src/Factory.sol";
import "src/CentralRegistry.sol";
import "src/Master.sol";
import "src/LeveragedNFT.sol";
import "src/interfaces/IMaster.sol";
import "src/interfaces/IERC721Receiver.sol";

// Using WBTC on this test because WETH is not working on my fork

contract Using_Proxy_Long_Base_Odos_ZeroLend_Test is Test, IERC721Receiver {

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WBTCAddress = 0x3aAB2285ddcDdaD8edf438C1bAB47e1a9D05a9b4;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Long_Quote_Odos_Zerolend longQuoteOdosZerolend;
    Long_Base_Odos_Zerolend longBaseOdosZerolend;

    uint256 ONE_MILLION_SATS = 10000000;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff00013aab2285ddcddad8edf438c1bab47e1a9d05a9b405031bf5de8004013143b6028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000010050412015cea294a0a0100010201014e40cb8f0a0100030201010d7df92e0a0100040201012db897d80a0100050201012cf7b14b0a0100060201010d666be00a0201070201015e5aa6440a0201080201000a030009020102000007b7675e150a00000a0b01060a00000c0b0101541fd0970a02010d0e0001667893e60a02010f0e0001b2aac8270a0201100e00000a0201110e00ff00000000000000000000003cb104f044db23d6513f2a6100a1997fa5e3f587176211869ca2b568f2a7d4ee941e073a821ee1ff64bccad8e7302e81b09894f56f6bba85ae82cd03d5539d0360438a66661148c633a9f0965e482845586733678b9ac9da43dd7cb83bbb41d23677dfc3c48622190a6b91d64ee7459c62fade9abe61b48a1d6cbd5ab95fcc04edde14abfa8d363adf4ead000ab43d592f8fa273ce900d8749c854419e8e1459efd5ec2cc043e3bd3c840f7998cc42ee712700ba8611456f845293edd3f5788277f00f7c05ccc291a219439258ca9da29e9cc4ce5596924745e12b9327ed78122b8ef363f4ef5b3afe197e0c4a2fa5148e80016b025c89a6a270b399f5ebfb734be58adae5d7c2a44ffddf6b295a15c148167daaaf5cf34ff11bb479dc3daffe63989b6b95f6c119225dac285afda31027c3e6a03c77a113ffc031b564abbf05a22206521a460aa6b21a089c3b48ffd0c79d5fd5000000000000000000000000";

    bytes odosRemove = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff0738d7ea4c68000004035123f6028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000d5539d0360438a66661148c633a9f0965e482845e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';

    bytes odosClose = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff080132584c89e56f4d0411e00b82028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';
    
    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    function setUp() public {

        centralRegistry = new CentralRegistry();
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend();
        longBaseOdosZerolend = new Long_Base_Odos_Zerolend();

        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addImplementation("LONG_QUOTE_ODOS_ZEROLEND", address(longBaseOdosZerolend));
        
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);

    }

    function testCreatePosition() public {
        deal(WBTCAddress, (address(this)), ONE_MILLION_SATS, true);

        IERC20(WBTCAddress).approve(address(master), ONE_MILLION_SATS);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: address(longBaseOdosZerolend),
            quoteToken: USDCAddress,
            baseToken: WBTCAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        IMaster.PositionParams memory position = IMaster.PositionParams({
            collateralAmount: ONE_MILLION_SATS,
            flashLoanAmount: 13354000000,
            pathDefinition: odosAdd
        });

        IERC20(WBTCAddress).approve(address(master), ONE_MILLION_SATS);

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