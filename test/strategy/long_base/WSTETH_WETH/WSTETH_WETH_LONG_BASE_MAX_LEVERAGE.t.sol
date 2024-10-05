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



contract WSTETH_WETH_LONG_BASE_MAX_LEVERAGE is Test, IERC721Receiver {

    address WSTETHAddress = 0xB5beDd42000b71FddE22D3eE8a79Bd49A568fC8F;
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

    bytes odosAdd = hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001b5bedd42000b71fdde22d3ee8a79bd49a568fc8f0803c9e40db7ae8000080335b4ea226c3420028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce982100001C1b80472388e830d015C8089Cc39895b14040DFf00019051C36E249109588209603d470216f1595D4d9e000000000301020300100101000102ff000000000000000000000000000000000000000000c1b80472388e830d015c8089cc39895b14040dffe5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000";

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
        deal(WSTETHAddress, address(this), 1 ether, true);

        IERC20(WSTETHAddress).approve(address(master), 1 ether);

    }

    function testMaxLeverageWSTETHWETH() public {

        uint256 marginAmount = 0.1 ether;

        uint256 flashLoanAmount = 0.273 ether;

        IMaster.NewPositionParams memory newPositionParams = IMaster.NewPositionParams({
            implementation: "LONG_BASE_ODOS_ZEROLEND",
            quoteToken: WETHAddress,
            baseToken: WSTETHAddress
        });

        IMaster.PositionParams memory positionParams = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: marginAmount,
            flashLoanAmount: flashLoanAmount,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).createAndAddToPosition(newPositionParams, positionParams, address(this));

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