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

contract Deeper_Add_Long_Quote is Test, IERC721Receiver {

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

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411e1a3000801a86ab8b1e380c0028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000301020401455b66200a0101010201000a0101030201ff00000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff7077f0cff76077d0ebb335b607db57440051055700000000";

    bytes odosRemove = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0401751c7c071ff6cfece8c47f028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';

    bytes odosClose = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff080132584c89e56f4d0411e00b82028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';
    
    // incorrect path definitions

    bytes odosAddIncorrect = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411490c8008019b799bb62c1ef0028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000802040a0133e7783c0a0100010201018b1fd4c60a0200030201000a030104020104000002080000050601c08c3ab80a0301070801000d0301090801ff00000000d4d4d99b26e7c96c70f32b417870aad2d51374a5176211869ca2b568f2a7d4ee941e073a821ee1ffefd5ec2cc043e3bd3c840f7998cc42ee712700ba7077f0cff76077d0ebb335b607db5744005105578b1251076f23ffa2a2a6459583c587c1cdbb2c6e7d43aabc515c356145049227cee54b608342c0ad1947b87d35e9f1cd53cede1ad6f7be44c12212b8a219439258ca9da29e9cc4ce5596924745e12b9363d4904e63571884b7930bb14a810141ac518683000000000000000000000000';

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

    }

    function testFail_CreatePosition_Bad_Implementation() public {
        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "NOT_AN_IMPLEMENTATION",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

    
        IMaster(address(master)).createPosition(params);
    }

    function testFail_CreateZeroAddress() public {
        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_QUOTE_ODOS_ZEROLEND",
            quoteToken: address(0),
            baseToken: WETHAddress
        });

        IMaster(address(master)).createPosition(params);
    }

    function testFail_CreateZeroAddress2() public {
        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: address(0)
        });

        IMaster(address(master)).createPosition(params);
    }

    function testFail_NotNFTOwner() public {
        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster(address(master)).createPosition(params);

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 100 * 10**6,
            flashLoanAmount: 0.061 ether,
            pathDefinition: odosAdd
        });

        address wrongAddress = 0x2bf397d0Fe53ca48182966fc3D742fdA2aC8c1F0;

        vm.prank(wrongAddress);

        IMaster(address(master)).addToPosition(
            0,
            positionParams
        );
    }

    function testFail_DirectCall() public {
        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        (uint256 tokenId, address proxyAddress) = IMaster(address(master)).createPosition(params);

        IProxy(proxyAddress).addToPosition(100 * 10**6, 0.061 ether, odosAdd);

    }

    // does not swap the entire in amount, should refund the user the leftover USDC
    function testNotSwapFullAmount() public {

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
            implementation: "LONG_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        (uint256 tokenId, address proxyAddress) = IMaster(address(master)).createPosition(params);

        IMaster.PositionParams memory position = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 100 * 10**6,
            flashLoanAmount: 200 * 10**6,
            pathDefinition: odosAddIncorrect // with 10000000 not used to swap in
        });

        deal(USDCAddress, (address(this)), 100 * 10**6, true);

        IERC20(USDCAddress).approve(address(master), 100 * 10**6);

        IMaster(address(master)).addToPosition(tokenId, position);

        assertEq(IERC20(USDCAddress).balanceOf(address(this)), 10000000);


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