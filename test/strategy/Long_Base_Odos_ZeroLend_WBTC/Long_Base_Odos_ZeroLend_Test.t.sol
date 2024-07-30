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

contract Using_Proxy_Long_Base_Odos_ZeroLend_Test_WBTC is Test, IERC721Receiver {

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

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff00013aab2285ddcddad8edf438c1bab47e1a9d05a9b40450ddc070031e791d028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e200000000060202070161afb6040a0100010201018384be280a0100030201000d0100040201020a0001050600ff000000000000000000000000000000000000000000000000d5539d0360438a66661148c633a9f0965e482845176211869ca2b568f2a7d4ee941e073a821ee1ff586733678b9ac9da43dd7cb83bbb41d23677dfc35615a7b1619980f7d6b5e7f69f3dc093dfe0c95cf11bb479dc3daffe63989b6b95f6c119225dac28e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0000000000000000";

    bytes odosRemove = hex'83bd37f900013aab2285ddcddad8edf438c1bab47e1a9d05a9b40001176211869ca2b568f2a7d4ee941e073a821ee1ff030f44340428a16959028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e200000000050102060183e2ec070a0100010201000a0100030201020a0001040500ff0000005afda31027c3e6a03c77a113ffc031b564abbf053aab2285ddcddad8edf438c1bab47e1a9d05a9b4a22206521a460aa6b21a089c3b48ffd0c79d5fd5586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f00000000000000000000000000000000000000000000000000000000';

    bytes odosClose = hex'83bd37f900013aab2285ddcddad8edf438c1bab47e1a9d05a9b40001176211869ca2b568f2a7d4ee941e073a821ee1ff031e84800450fd17ca028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000802020a000a01000102010333fab9c00a000003040003a3f48ab20a000005040003c07cd86a0a0000060400020d0000070400000a0101080900ff0000000000005afda31027c3e6a03c77a113ffc031b564abbf053aab2285ddcddad8edf438c1bab47e1a9d05a9b48611456f845293edd3f5788277f00f7c05ccc291e5d7c2a44ffddf6b295a15c148167daaaf5cf34f27ed78122b8ef363f4ef5b3afe197e0c4a2fa5141947b87d35e9f1cd53cede1ad6f7be44c12212b863d4904e63571884b7930bb14a810141ac518683efd5ec2cc043e3bd3c840f7998cc42ee712700baa219439258ca9da29e9cc4ce5596924745e12b93000000000000000000000000';
    
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
        centralRegistry.addImplementation("LONG_BASE_ODOS_ZEROLEND", address(longBaseOdosZerolend));
        
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);

    }

    function testCreatePosition() public {

        deal(WBTCAddress, (address(this)), TEN_MILLION_SATS, true);

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_BASE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WBTCAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        IMaster.PositionParams memory position = IMaster.PositionParams({
            marginAmount: ONE_MILLION_SATS,
            flashLoanAmount: 1356710000,
            pathDefinition: odosAdd
        });

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster(address(master)).addToPosition(0, position);
    }

    function testRemovePosition() public {
        deal(WBTCAddress, (address(this)), TEN_MILLION_SATS, true);

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_BASE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WBTCAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        // increase the exposure to 0.03 BTC to a 3X Leveraged position
        IMaster.PositionParams memory position = IMaster.PositionParams({
            marginAmount: ONE_MILLION_SATS,
            flashLoanAmount: 1359640000, // 2M SATS in USDC price
            pathDefinition: odosAdd
        });

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster(address(master)).addToPosition(0, position);

        // unwind position by paying loan and removing base from collateral
        // 1. determine how much of the loan to repay
        // 2. get a flashloan of at least the flash loan amount + premium, if more it increases exposure.
        // 3. withdraw base from collateral to repay loan + premium in USDC
        // 4. swap base to USDC
        // 5. repay flashloan

        // 678.36 USDC flash loan amount
        // 678.36 * 100.05% [premium] = 679.05 USDC
        // 100.05% of 1 million satoshi = 1000500

        IMaster.PositionParams memory removeParams = IMaster.PositionParams({
            marginAmount: 1000500,
            flashLoanAmount: 678360000,
            pathDefinition: odosRemove
        });

        // params: _tokenId, _baseReductionAmount, _flashLoanAmount, _pathDefinition
        IMaster(address(master)).removeFromPosition(0, removeParams);


    }
    
    function testClosePosition() public {
        deal(WBTCAddress, (address(this)), TEN_MILLION_SATS, true);

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_BASE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WBTCAddress
        });

        IMaster(address(master)).createPosition(params);

        uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        assertEq(nftBalance, 1);

        // increase the exposure to 0.03 BTC to a 3X Leveraged position
        IMaster.PositionParams memory position = IMaster.PositionParams({
            marginAmount: ONE_MILLION_SATS,
            flashLoanAmount: 1356710000, // 2M SATS in USDC price
            pathDefinition: odosAdd
        });

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster(address(master)).addToPosition(0, position);

        IMaster(address(master)).closePosition(0, odosClose);
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