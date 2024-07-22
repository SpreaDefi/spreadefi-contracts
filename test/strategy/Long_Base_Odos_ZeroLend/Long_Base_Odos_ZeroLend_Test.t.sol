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

    uint256 TEN_MILLION_SATS = 10_000_000;
    uint256 FIVE_MILLION_SATS = 5_000_000;
    uint256 ONE_MILLION_SATS = 1_000_000;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff00013aab2285ddcddad8edf438c1bab47e1a9d05a9b40601da54128c400443266b7f028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000501020601633a467b0801000102000a0100030201020000000a0101040500ff005ec5b1e9b1bd5198343abb6e55fb695d2f7bb308176211869ca2b568f2a7d4ee941e073a821ee1ff64bccad8e7302e81b09894f56f6bba85ae82cd038e80016b025c89a6a270b399f5ebfb734be58adae5d7c2a44ffddf6b295a15c148167daaaf5cf34f00000000000000000000000000000000000000000000000000000000";

    bytes odosRemove = hex'83bd37f900013aab2285ddcddad8edf438c1bab47e1a9d05a9b40001176211869ca2b568f2a7d4ee941e073a821ee1ff034c4b4004c704bc9b028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000802030a0199e564480a0100010201000a010003020103d20387d90000020a02000405000153f59b150a0101060500000a0101070500040a0101080900ff0000008e80016b025c89a6a270b399f5ebfb734be58ada3aab2285ddcddad8edf438c1bab47e1a9d05a9b45afda31027c3e6a03c77a113ffc031b564abbf051947b87d35e9f1cd53cede1ad6f7be44c12212b8e5d7c2a44ffddf6b295a15c148167daaaf5cf34f3cb104f044db23d6513f2a6100a1997fa5e3f587586733678b9ac9da43dd7cb83bbb41d23677dfc3efd5ec2cc043e3bd3c840f7998cc42ee712700baa219439258ca9da29e9cc4ce5596924745e12b93000000000000000000000000';

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

    // function testCreatePosition() public {
    //     deal(WBTCAddress, (address(this)), TEN_MILLION_SATS, true);

    //     IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

    //     IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
    //         implementation: address(longBaseOdosZerolend),
    //         quoteToken: USDCAddress,
    //         baseToken: WBTCAddress
    //     });

    //     IMaster(address(master)).createPosition(params);

    //     uint256 nftBalance = leveragedNFT.balanceOf(address(this));

    //     assertEq(nftBalance, 1);

    //     IMaster.PositionParams memory position = IMaster.PositionParams({
    //         collateralAmount: TEN_MILLION_SATS,
    //         flashLoanAmount: 13354000000,
    //         pathDefinition: odosAdd
    //     });

    //     IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

    //     IMaster(address(master)).addToPosition(0, position);
    // }

    function testRemovePosition() public {
        deal(WBTCAddress, (address(this)), TEN_MILLION_SATS, true);

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: address(longBaseOdosZerolend),
            quoteToken: USDCAddress,
            baseToken: WBTCAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        // increase exposure to 40M sats, 4x leveraged position
        IMaster.PositionParams memory position = IMaster.PositionParams({
            collateralAmount: TEN_MILLION_SATS,
            flashLoanAmount: 2037225000000, // USDC price of 0.2 BTC, Twenty Million Sats
            pathDefinition: odosAdd
        });

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster(address(master)).addToPosition(0, position);

        // unwind position by paying loan and removing base from collateral
        // 1. determine how much of the loan to repay
        // 2. get a flashloan of at least the amount to repay in USDC, if more it increases exposure.
        // 3. withdraw base from collateral to repay loan + premium in USDC
        // 4. swap base to USDC
        // 5. repay flashloan


        // IMaster(address(master)).removeFromPosition(0, FIVE_MILLION_SATS, 3362500000, odosRemove);


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