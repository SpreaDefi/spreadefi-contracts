// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";

import "src/implementations/Long_Quote_Odos_Zerolend.sol";
import "src/implementations/Long_Base_Odos_Zerolend_Refactor.sol";
import "src/Factory.sol";
import "src/CentralRegistry.sol";
import "src/Master.sol";
import "src/LeveragedNFT.sol";
import "src/interfaces/IMaster.sol";
import "src/interfaces/IERC721Receiver.sol";
import "src/interfaces/external/weth/IWETH.sol";


contract Zero_Margin_Test is Test, IERC721Receiver {

    address testRecipient = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    address WSTETHAddress = 0xB5beDd42000b71FddE22D3eE8a79Bd49A568fC8F;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Long_Quote_Odos_Zerolend longQuoteOdosZerolend;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

   event debug(string message, uint256 value);
    event debugAddress(string message, address value);

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001b5bedd42000b71fdde22d3ee8a79bd49a568fc8f0802c68af0bb140000080259b492a713bac0028f5c00018e7591e2919157A6BBE9E3defe0F1Ff793e65Ec1000000019051C36E249109588209603d470216f1595D4d9e0000000003010203000a0101010200ff0000000000000000000000000000000000000000000180912f869065c7a44617cd4c288be6bce5d192e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000";

    bytes odosAddNoMargin = hex'83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001b5bedd42000b71fdde22d3ee8a79bd49a568fc8f072386f26fc10000071e15edb1cbfa8d028f5c00018e7591e2919157A6BBE9E3defe0F1Ff793e65Ec1000000019051C36E249109588209603d470216f1595D4d9e0000000003010203000a0101010200ff0000000000000000000000000000000000000000005feb94125e9d7f143ec9d1f88b313d738f904f61e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000';

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    function setUp() public {

        // deploy core contracts
        centralRegistry = new CentralRegistry(address(this));
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend();

        // set up central registry
        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addImplementation("LONG_QUOTE_ODOS_ZEROLEND", address(longQuoteOdosZerolend));
        
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);

        // give tokens to this contract and approve master to spend them
        IWETH(WETHAddress).deposit{value: 1 ether}();
        
        IERC20(WETHAddress).approve(address(master), 1 ether);

    }

    function testZeroMargin() public {

        uint256 marginAmount = 0.1 ether; // WETH

        uint256 flashLoanAmount = 0.1 ether;

        IMaster.NewPositionParams memory newPositionParams = IMaster.NewPositionParams({
            implementation: "LONG_QUOTE_ODOS_ZEROLEND",
            quoteToken: WETHAddress,
            baseToken: WSTETHAddress
        });

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: marginAmount,
            flashLoanAmount: flashLoanAmount,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).createAndAddToPosition(newPositionParams, positionParams, address(this));

        emit debug("DONE CREATING POSITION", 696969696969696696969);

        // adding to position with zero margin
        IMaster.PositionParams memory positionParamsZeroMargin = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 0,
            flashLoanAmount: 0.01 ether,
            pathDefinition: odosAddNoMargin
        });

        IMaster(address(master)).addToPosition(0, positionParamsZeroMargin);

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