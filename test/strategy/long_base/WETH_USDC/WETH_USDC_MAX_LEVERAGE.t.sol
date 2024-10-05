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



contract WETH_USDC_LONG_BASE_MAX_LEVERAGE is Test, IERC721Receiver {

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Long_Base_Odos_Zerolend longBaseOdosZerolend;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

    event debug(string message, uint256 value);
    event debugAddress(string message, address value);

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0438538e400805884b7d4b355400028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000019051C36E249109588209603d470216f1595D4d9e000000000e0405100118d9d9aa0a01000102010113e583670a0201030201011b8c2adb0a0201040201014245f3980d0201050201014418722a10020101060201c50dd0170a0300070201000a0400080201080a0201090a0107bc42b6b80a02010b0c01060a02010d0c01020a02010e0f01ff000000000000000000000000000000000000001d6cbd5ab95fcc04edde14abfa8d363adf4ead00176211869ca2b568f2a7d4ee941e073a821ee1ffe4f5dc6cab4b23e124d3a73a2cfee32dc070f72d7077f0cff76077d0ebb335b607db5744005105575615a7b1619980f7d6b5e7f69f3dc093dfe0c95cdded227d71a096c6b5d87807c1b5c456771aaa94efd5ec2cc043e3bd3c840f7998cc42ee712700baa48e0630b7b9dcb250112143c9d0fe47d26cb1e468594a53fc98eea213784534f44bcc08248b4e784af15ec2a0bd43db75dd04e62faa3b8ef36b00d527ed78122b8ef363f4ef5b3afe197e0c4a2fa514a219439258ca9da29e9cc4ce5596924745e12b931947b87d35e9f1cd53cede1ad6f7be44c12212b8a22206521a460aa6b21a089c3b48ffd0c79d5fd53aab2285ddcddad8edf438c1bab47e1a9d05a9b40000000000000000000000000000000000000000";

    bytes odosRemove = hex'83bd37f900013aab2285ddcddad8edf438c1bab47e1a9d05a9b40001176211869ca2b568f2a7d4ee941e073a821ee1ff030188940403933b6e028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000004010205000801000102020a0001030400ff000000000000000000000000000000f5783661c3bac33373ecf8977fc0df1feb7886fa3aab2285ddcddad8edf438c1bab47e1a9d05a9b47077f0cff76077d0ebb335b607db574400510557e5d7c2a44ffddf6b295a15c148167daaaf5cf34f00000000000000000000000000000000';

    bytes odosClose = hex'83bd37f900013aab2285ddcddad8edf438c1bab47e1a9d05a9b40001176211869ca2b568f2a7d4ee941e073a821ee1ff031e5cde0446859ebe028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000702030801b96655730a0100010201000a0201030200037a3c4fa90a0201040500039316a7c10a0201060500020d0201070500ff000000000000000000000000008e80016b025c89a6a270b399f5ebfb734be58ada3aab2285ddcddad8edf438c1bab47e1a9d05a9b40ab43d592f8fa273ce900d8749c854419e8e1459586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f7077f0cff76077d0ebb335b607db5744005105575615a7b1619980f7d6b5e7f69f3dc093dfe0c95c0000000000000000000000000000000000000000';
    
    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    function setUp() public {

        // deploy core contracts
        centralRegistry = new CentralRegistry(address(this));
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        longBaseOdosZerolend = new Long_Base_Odos_Zerolend();

        // set up central registry
        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addImplementation("LONG_BASE_ODOS_ZEROLEND", address(longBaseOdosZerolend));
        
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);

        // give tokens to this contract and approve master to spend them
        deal(USDCAddress, address(this), 100 * 10**6, true);
        // get weth
        IWETH(WETHAddress).deposit{value: 1 ether}();
        
        IERC20(WETHAddress).approve(address(master), 100 ether);
        IERC20(USDCAddress).approve(address(master), 100 * 10**6);

    }


    function testMaxLeverageUSDCWETH() public {

        uint256 flashLoanAmount = 945000000;

        IMaster.NewPositionParams memory newPositionParams = IMaster.NewPositionParams({
            implementation: "LONG_BASE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 0.1 ether,
            flashLoanAmount: flashLoanAmount,
            pathDefinition: odosAdd
        });

        (uint256 tokenId, address proxyAddress) = IMaster(address(master)).createAndAddToPosition(
            newPositionParams,
            positionParams,
            address(this)
        );

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