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
import "src/Monitor.sol";

// Using WBTC on this test because WETH is not working on my fork

contract LongBase_ZeroParams is Test, IERC721Receiver {

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WBTCAddress = 0x3aAB2285ddcDdaD8edf438C1bAB47e1a9D05a9b4;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Long_Base_Odos_Zerolend longBaseOdosZerolend;

    Monitor monitor;

    uint256 TEN_MILLION_SATS = 10_000_000;
    uint256 FIVE_MILLION_SATS = 5_000_000;
    uint256 ONE_MILLION_SATS = 1_000_000;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

    address PROXY_ADDRESS;

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff00013aab2285ddcddad8edf438c1bab47e1a9d05a9b404232a6160030f4900028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000004010205000a0100010201020a0001030400ff000000000000000000000000000064bccad8e7302e81b09894f56f6bba85ae82cd03176211869ca2b568f2a7d4ee941e073a821ee1ff5afda31027c3e6a03c77a113ffc031b564abbf05e5d7c2a44ffddf6b295a15c148167daaaf5cf34f00000000000000000000000000000000";

    bytes odosRemove = hex'83bd37f900013aab2285ddcddad8edf438c1bab47e1a9d05a9b40001176211869ca2b568f2a7d4ee941e073a821ee1ff030188940403933b6e028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000004010205000801000102020a0001030400ff000000000000000000000000000000f5783661c3bac33373ecf8977fc0df1feb7886fa3aab2285ddcddad8edf438c1bab47e1a9d05a9b47077f0cff76077d0ebb335b607db574400510557e5d7c2a44ffddf6b295a15c148167daaaf5cf34f00000000000000000000000000000000';

    bytes odosClose = hex'83bd37f900013aab2285ddcddad8edf438c1bab47e1a9d05a9b40001176211869ca2b568f2a7d4ee941e073a821ee1ff031e5cde0446859ebe028f5c00017D2b63A9ab475397d9c247468803F25Cf6523B76000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e2000000000702030801b96655730a0100010201000a0201030200037a3c4fa90a0201040500039316a7c10a0201060500020d0201070500ff000000000000000000000000008e80016b025c89a6a270b399f5ebfb734be58ada3aab2285ddcddad8edf438c1bab47e1a9d05a9b40ab43d592f8fa273ce900d8749c854419e8e1459586733678b9ac9da43dd7cb83bbb41d23677dfc3e5d7c2a44ffddf6b295a15c148167daaaf5cf34f7077f0cff76077d0ebb335b607db5744005105575615a7b1619980f7d6b5e7f69f3dc093dfe0c95c0000000000000000000000000000000000000000';
    
    bytes odosAddNoMargin = hex'83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff00013aab2285ddcddad8edf438c1bab47e1a9d05a9b40405f5e1000302970e028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000014f81992FCe2E1846dD528eC0102e6eE1f61ed3e20000000003010203000a0101010201ff0000000000000000000000000000000000000000001d6cbd5ab95fcc04edde14abfa8d363adf4ead00176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000';

    /* %%%%%%%%%%%%%%%% ODOS API VARIABLES %%%%%%%%%%%%%%%% */

    function setUp() public {

        centralRegistry = new CentralRegistry(address(this));
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        longBaseOdosZerolend = new Long_Base_Odos_Zerolend();

        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addImplementation("LONG_BASE_ODOS_ZEROLEND", address(longBaseOdosZerolend));
        
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);

        deal(WBTCAddress, (address(this)), TEN_MILLION_SATS, true);

        IERC20(WBTCAddress).approve(address(master), TEN_MILLION_SATS);

        IMaster.NewPositionParams memory newPositionParams = IMaster.NewPositionParams({
            implementation: "LONG_BASE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WBTCAddress
        });

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: ONE_MILLION_SATS,
            flashLoanAmount: 589_980000,
            pathDefinition: odosAdd
        });

        (uint256 tokenId, address proxyAddress) = IMaster(address(master)).createAndAddToPosition(newPositionParams, positionParams);

    }

    function testAddNoMargin() public {

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 0,
            flashLoanAmount: 100_000000,
            pathDefinition: odosAddNoMargin
        });

        IMaster(address(master)).addToPosition(0, positionParams);

    }

    function testAddNoFlashloan() public {
            
            IMaster.PositionParams memory positionParams = IMaster.PositionParams({
                marginAmountOrCollateralReductionAmount: 85008,
                flashLoanAmount: 0,
                pathDefinition: odosAddNoMargin
            });
    
            IMaster(address(master)).addToPosition(0, positionParams);
    }

    function testRemoveNoFlashloan() public {
            
            IMaster.PositionParams memory positionParams = IMaster.PositionParams({
                marginAmountOrCollateralReductionAmount: 85008,
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