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

    address PROXY_ADDRESS;

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411e1a3000801a20fd764263750028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010204018e56483f0a0101010201000a0101030201ff00000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff7077f0cff76077d0ebb335b607db57440051055700000000";

    bytes odosRemove = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff07254db1c224400004019b23de028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000c48622190a6b91d64ee7459c62fade9abe61b48ae5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';

    bytes odosClose = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff080132584c89e56f4d0411e00b82028f5c0001d804BA88371A3f00dDaCA03Cbc2b6C47F38105FC000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010200ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';
    
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

    // function testCreatePosition() public {
        
    //     deal(USDCAddress, (address(this)), 100 * 10**6, true);

    //     IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
    //         implementation: "LONG_QUOTE_ODOS_ZEROLEND",
    //         quoteToken: USDCAddress,
    //         baseToken: WETHAddress
    //     });

    //     (uint256 tokenID, address proxyAddress) = IMaster(address(master)).createPosition(params);

    //     PROXY_ADDRESS = proxyAddress;

    //     IERC20(USDCAddress).approve(PROXY_ADDRESS, 100 * 10**6);

    //     uint256 nftBalance = leveragedNFT.balanceOf(address(this));

    //     assertEq(nftBalance, 1);

    //     IMaster.PositionParams memory position = IMaster.PositionParams({
    //         marginAmountOrCollateralReductionAmount: 100 * 10**6,
    //         flashLoanAmount: 200 * 10**6,
    //         pathDefinition: odosAdd
    //     });

    //     IMaster(address(master)).addToPosition(0, position);

    // }

    // function testLowerExposure() public {

    //     deal(USDCAddress, (address(this)), 100 * 10**6, true);

    //     IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
    //         implementation: "LONG_QUOTE_ODOS_ZEROLEND",
    //         quoteToken: USDCAddress,
    //         baseToken: WETHAddress
    //     });

    //     (uint256 tokenID, address proxyAddress) = IMaster(address(master)).createPosition(params);

    //     PROXY_ADDRESS = proxyAddress;

    //     IERC20(USDCAddress).approve(PROXY_ADDRESS, 100 * 10**6);

    //     uint256 nftBalance = leveragedNFT.balanceOf(address(this));

    //     assertEq(nftBalance, 1);

    //     IMaster.PositionParams memory position = IMaster.PositionParams({
    //         marginAmountOrCollateralReductionAmount: 100 * 10**6,
    //         flashLoanAmount: 200 * 10**6,
    //         pathDefinition: odosAdd
    //     });

    //     IMaster(address(master)).addToPosition(0, position);

    //     uint256 baseReduction = 0.0105 ether;
    //     uint256 flashLoanAmount = 25_620000;

    //     IMaster.PositionParams memory removeParams = IMaster.PositionParams({
    //         marginAmountOrCollateralReductionAmount: baseReduction,
    //         flashLoanAmount: flashLoanAmount,
    //         pathDefinition: odosRemove
    //     });

    //     IMaster(address(master)).removeFromPosition(0, removeParams);
    // }


    // function testClosePosition() public {

    //     deal(USDCAddress, (address(this)), 100 * 10**6, true);

    //     IMaster.NewPositionParams memory params = IMaster.NewPositionParams({
    //         implementation: "LONG_QUOTE_ODOS_ZEROLEND",
    //         quoteToken: USDCAddress,
    //         baseToken: WETHAddress
    //     });

    //     (uint256 tokenID, address proxyAddress) = IMaster(address(master)).createPosition(params);

    //     PROXY_ADDRESS = proxyAddress;

    //     IERC20(USDCAddress).approve(PROXY_ADDRESS, 100 * 10**6);

    //     uint256 nftBalance = leveragedNFT.balanceOf(address(this));

    //     assertEq(nftBalance, 1);

    //     IMaster.PositionParams memory position = IMaster.PositionParams({
    //         marginAmountOrCollateralReductionAmount: 100 * 10**6,
    //         flashLoanAmount: 200 * 10**6,
    //         pathDefinition: odosAdd
    //     });

    //     IMaster(address(master)).addToPosition(0, position);

    //     IMaster(address(master)).closePosition(0, odosClose);

    // }

    function testCreateAndAdd() public {
            
            deal(USDCAddress, (address(this)), 100 * 10**6, true);
    
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

            IERC20(USDCAddress).approve(address(master), 100 * 10**6);
    
            (uint256 tokenID, address proxyAddress) = IMaster(address(master)).createAndAddToPosition(params, position);

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