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

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff00013aab2285ddcddad8edf438c1bab47e1a9d05a9b40601ca8f2b484004ae3591e4028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000002c0f062f01046cf1b108010001020100882e04030100010302011e0158b894720a010004020101570180480a0100050201010e286ec70a01000602010116e7bb580a01000702010105523a160a0100080201011460a33f0a01000902010107d9729d0d01000a0201010c7c93390d01000b020101018cc71e130100010c02013408f919090100020d012317132e0802000e020134dbadef0a02000f0201014788a5f30a02001002010157fb880d0a02001102010107540a940a02001202010158b42c270d02001302010109d7cbf108030014020110f8c7db0a030015020101125a7beb0a030016020101134b569d0a0400170201011afac9f20a0501180201000a050119020102000008000105036f871b0800001a1b05b530117a0a00001c1b0105a76a69c30a00001d1b01051828029a0a00001e1b0105c57873250a00001f1b01040d0000201b0107c668077d0a0000212201060d000023220101009e5c06080501240d0101642eeb03050101250d001e018833a0370a0501260d0001a567233f0a0501270d000114590df70a0501280d00015c729c930a0501290d0001df2b7d750a05012a0d00017975ef730d05012b0d0000130501012c0d020a05012d2e01ff0000000000000000000000000000000000000000000000000000000000005ec5b1e9b1bd5198343abb6e55fb695d2f7bb308176211869ca2b568f2a7d4ee941e073a821ee1ff51a056cc4eb7d1feb896554f97aa01805d41f1903cb104f044db23d6513f2a6100a1997fa5e3f58764bccad8e7302e81b09894f56f6bba85ae82cd03d5539d0360438a66661148c633a9f0965e482845586733678b9ac9da43dd7cb83bbb41d23677dfc37077f0cff76077d0ebb335b607db574400510557c48622190a6b91d64ee7459c62fade9abe61b48a564e52bbdf3adf10272f3f33b00d65b2ee48afff5615a7b1619980f7d6b5e7f69f3dc093dfe0c95cdded227d71a096c6b5d87807c1b5c456771aaa94e5d7c2a44ffddf6b295a15c148167daaaf5cf34f258d5f860b11ec73ee200eb14f1b60a3b7a536a26e9ad0b8a41e2c148e7b0385d3ecbfdb8a216a9befd5ec2cc043e3bd3c840f7998cc42ee712700ba6a72f4f191720c411cd1ff6a5ea8dedec3a647715856edf9212bdcec74301ec78afc573b62d6a283e14f01667e2c2955b41c50a2ac39680a66f2bdeb2f26e02696fdd24b7404f1be44562341bb0d7477b3693eaca83136b1b9f17f65d1b6399f6d4c7da1a48e0630b7b9dcb250112143c9d0fe47d26cb1e4dda5ec5af00ab99dc80c33e08881eb80c027d4981d6cbd5ab95fcc04edde14abfa8d363adf4ead000ab43d592f8fa273ce900d8749c854419e8e14598aebffb3964ec5cea0915080ddc1aca079583a4da219439258ca9da29e9cc4ce5596924745e12b938611456f845293edd3f5788277f00f7c05ccc29127ed78122b8ef363f4ef5b3afe197e0c4a2fa514c014414696f332c96c471634620344143325d2c01947b87d35e9f1cd53cede1ad6f7be44c12212b863d4904e63571884b7930bb14a810141ac51868368594a53fc98eea213784534f44bcc08248b4e784af15ec2a0bd43db75dd04e62faa3b8ef36b00d57e0bd7da078551a85d0e14373646759c3976e227f5783661c3bac33373ecf8977fc0df1feb7886fa38d4b2627ff87911410129849246a1a19f5868738e80016b025c89a6a270b399f5ebfb734be58adaf11bb479dc3daffe63989b6b95f6c119225dac28bd3bc396c9393e63bbc935786dd120b17f58df4c5afda31027c3e6a03c77a113ffc031b564abbf05a22206521a460aa6b21a089c3b48ffd0c79d5fd510656d09115bbe6be89bf6a66d4949f833566a2495a849bf8613492241bcbda00c2e43af4f78888932858cb23950f6981bd3d1bb11cc36da83de9cfb1a51b19ce03dbe0cb44c1528e34a7edd7771e9af0000000000000000";

    bytes odosRemove = hex'83bd37f900013aab2285ddcddad8edf438c1bab47e1a9d05a9b40001176211869ca2b568f2a7d4ee941e073a821ee1ff034c4b4004c338c874028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000b03040d010c7102ba0a0101010200013e8bec520a0101030200000a020004020105aba658fe0000054c070ff50a030005060005bb12f3180a0300070600040d0300080600060a0101090a0001d88108250a01010b0600000a01010c0600ff00001d6cbd5ab95fcc04edde14abfa8d363adf4ead003aab2285ddcddad8edf438c1bab47e1a9d05a9b40ab43d592f8fa273ce900d8749c854419e8e14595afda31027c3e6a03c77a113ffc031b564abbf0527ed78122b8ef363f4ef5b3afe197e0c4a2fa514e5d7c2a44ffddf6b295a15c148167daaaf5cf34f1947b87d35e9f1cd53cede1ad6f7be44c12212b863d4904e63571884b7930bb14a810141ac518683efd5ec2cc043e3bd3c840f7998cc42ee712700baa219439258ca9da29e9cc4ce5596924745e12b93586733678b9ac9da43dd7cb83bbb41d23677dfc37077f0cff76077d0ebb335b607db57440051055700000000000000000000000000000000';

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

        // deal(WBTCAddress, (address(this)), TEN_MILLION_SATS, true);

        // IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        // IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
        //     implementation: address(longBaseOdosZerolend),
        //     quoteToken: USDCAddress,
        //     baseToken: WBTCAddress
        // });

        // IMaster(address(master)).createPosition(params);

        // uint256 nftBalance = leveragedNFT.balanceOf(address(this));

        // assertEq(nftBalance, 1);

        // IMaster.PositionParams memory position = IMaster.PositionParams({
        //     collateralAmount: TEN_MILLION_SATS,
        //     flashLoanAmount: 13354000000,
        //     pathDefinition: odosAdd
        // });

        // IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        // IMaster(address(master)).addToPosition(0, position);
    }

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
        // 10 million sats as margin + 30 million sats from flashloan and swap
        IMaster.PositionParams memory position = IMaster.PositionParams({
            collateralAmount: TEN_MILLION_SATS,
            flashLoanAmount: 19694_97000000, // USDC price of 0.3 BTC, Thirty Million Sats
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


        IMaster(address(master)).removeFromPosition(0, FIVE_MILLION_SATS, 3282_50000000, odosRemove);


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