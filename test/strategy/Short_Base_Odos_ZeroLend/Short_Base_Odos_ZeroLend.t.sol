// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

import "src/implementations/Short_Base_Odos_Zerolend.sol";
import "src/Factory.sol";
import "src/CentralRegistry.sol";
import "src/Master.sol";
import "src/LeveragedNFT.sol";
import "src/interfaces/IMaster.sol";
import "src/interfaces/IERC721Receiver.sol";

contract Using_Proxy_Short_Base_Odos_ZeroLend_Test is Test, IERC721Receiver {

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Short_Base_Odos_Zerolend shortBaseOdosZerolend;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;
    
    error debugString(string message);

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff08013fbe85edc90000040e7e342f028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000301020401f32a84e30801010102000b0101030200ff00000000000000000000005ec5b1e9b1bd5198343abb6e55fb695d2f7bb308e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0cd67d85b51caaf7f6a2e3d4c6f557d4cc8d511800000000";

    bytes odosRemove = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0401a91c2007253e392e17cec0028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';

    bytes odosClose = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f040e40b1e108013f8c64d7039190028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000005010306012aafd0080a0101010201000a0200030201040a0101040501ff000000e4f5dc6cab4b23e124d3a73a2cfee32dc070f72d176211869ca2b568f2a7d4ee941e073a821ee1ff0ab43d592f8fa273ce900d8749c854419e8e1459a22206521a460aa6b21a089c3b48ffd0c79d5fd53aab2285ddcddad8edf438c1bab47e1a9d05a9b400000000000000000000000000000000000000000000000000000000';
    
    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    function setUp() public {
        centralRegistry = new CentralRegistry(address(this));
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        shortBaseOdosZerolend = new Short_Base_Odos_Zerolend();

        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addImplementation("SHORT_BASE_ODOS_ZEROLEND", address(shortBaseOdosZerolend));
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);
    
    }

    // function testCreatePosition() public {
    //     deal(WETHAddress, (address(this)), 100 * 10**6, false);

    //     IMaster.NewPositionParams memory params = IMaster.NewPositionParams ({
    //         implementation: "SHORT_BASE_ODOS_ZEROLEND",
    //         quoteToken: USDCAddress,
    //         baseToken: WETHAddress
    //     });

    //     IMaster(address(master)).createPosition(params);

    //     uint256 nftBalance = leveragedNFT.balanceOf(address(this));

    //     assertEq(nftBalance, 1);


    // }

    // function testAddPosition() public {
    //     deal(WETHAddress, (address(this)), 1 ether, false);

    //     IMaster.NewPositionParams memory params = IMaster.NewPositionParams ({
    //         implementation: "SHORT_BASE_ODOS_ZEROLEND",
    //         quoteToken: USDCAddress,
    //         baseToken: WETHAddress
    //     });

    //     (uint256 tokenId, address proxyAddress) = IMaster(address(master)).createPosition(params);

    //     uint256 nftBalance = leveragedNFT.balanceOf(address(this));

    //     assertEq(nftBalance, 1);

    //     IMaster.PositionParams memory positionParams = IMaster.PositionParams({
    //         marginAmountOrCollateralReductionAmount: 0.03 ether,
    //         flashLoanAmount: 0.06 ether,
    //         pathDefinition: odosAdd
    //     });

    //     IERC20(WETHAddress).approve(proxyAddress, 0.03 ether);

    //     IMaster(address(master)).addToPosition(
    //         0,
    //         positionParams
    //     );


    // }

    // function testRemove() public {
    //     deal(WETHAddress, (address(this)), 1 ether, false);

    //     IMaster.NewPositionParams memory params = IMaster.NewPositionParams ({
    //         implementation: "SHORT_BASE_ODOS_ZEROLEND",
    //         quoteToken: USDCAddress,
    //         baseToken: WETHAddress
    //     });

    //     (uint256 tokenId, address proxyAddress) = IMaster(address(master)).createPosition(params);

    //     uint256 nftBalance = leveragedNFT.balanceOf(address(this));

    //     assertEq(nftBalance, 1);

    //     IMaster.PositionParams memory positionParams = IMaster.PositionParams({
    //         marginAmountOrCollateralReductionAmount: 0.03 ether,
    //         flashLoanAmount: 0.06 ether,
    //         pathDefinition: odosAdd
    //     });

    //     IERC20(WETHAddress).approve(proxyAddress, 0.03 ether);

    //     IMaster(address(master)).addToPosition(
    //         0,
    //         positionParams
    //     );

    //     // lower exposure to eth
    //     IMaster.PositionParams memory removeParams = IMaster.PositionParams({
    //         marginAmountOrCollateralReductionAmount: 27860000, // usdc price of 0.01 ether
    //         flashLoanAmount: 0.01 ether,
    //         pathDefinition: odosRemove
    //     });

    //     IMaster(address(master)).removeFromPosition(
    //         0,
    //         removeParams
    //     );
    // }

    // function testClose() public {
    //     deal(WETHAddress, (address(this)), 1 ether, false);

    //     IMaster.NewPositionParams memory params = IMaster.NewPositionParams ({
    //         implementation: "SHORT_BASE_ODOS_ZEROLEND",
    //         quoteToken: USDCAddress,
    //         baseToken: WETHAddress
    //     });

    //     (uint256 tokenId, address proxyAddress) = IMaster(address(master)).createPosition(params);

    //     uint256 nftBalance = leveragedNFT.balanceOf(address(this));

    //     assertEq(nftBalance, 1);

    //     IMaster.PositionParams memory positionParams = IMaster.PositionParams({
    //         marginAmountOrCollateralReductionAmount: 0.03 ether,
    //         flashLoanAmount: 0.061 ether,
    //         pathDefinition: odosAdd
    //     });

    //     IERC20(WETHAddress).approve(proxyAddress, 0.03 ether);

    //     IMaster(address(master)).addToPosition(
    //         0,
    //         positionParams
    //     );

        
    //     IMaster(address(master)).closePosition(0, odosClose);

    // }

    function testCreateAndAdd() public {
        deal(WETHAddress, (address(this)), 1 ether, false);

        IMaster.NewPositionParams memory params = IMaster.NewPositionParams ({
            implementation: "SHORT_BASE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 0.03 ether,
            flashLoanAmount: 0.06 ether,
            pathDefinition: odosAdd
        });

        IERC20(WETHAddress).approve(address(master), 0.03 ether);

        IMaster(address(master)).createAndAddToPosition(params, positionParams);


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