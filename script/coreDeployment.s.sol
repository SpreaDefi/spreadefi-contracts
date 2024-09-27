// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "src/implementations/Long_Quote_Odos_Zerolend.sol";
import "src/implementations/Long_Base_Odos_Zerolend_Refactor.sol";
import "src/implementations/Short_Quote_Odos_Zerolend.sol";
import "src/implementations/Short_Base_Odos_Zerolend.sol";

import "src/Factory.sol";
import "src/CentralRegistry.sol";
import "src/Master.sol";
import "src/LeveragedNFT.sol";
import "src/interfaces/IMaster.sol";
import "src/interfaces/IERC721Receiver.sol";

contract CoreDeployment is Script, IERC721Receiver {
    event debugAddress(string, address);
    event debugUint(string, uint);

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    Long_Quote_Odos_Zerolend longQuoteOdosZerolend;
    Long_Base_Odos_Zerolend longBaseOdosZerolend;
    Short_Quote_Odos_Zerolend shortQuoteOdosZerolend;
    Short_Base_Odos_Zerolend shortBaseOdosZerolend;

    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

    address PROXY_ADDRESS;

    bytes getUSDC =
        hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff080de0b6b3a764000004979f1bdd028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce9821000000001f39Fd6e51aad88F6F4ce6aB8827279cffFb922660000000004010205013218bddc0801010102012abcc34e0a0101030200000901010204ff005ec5b1e9b1bd5198343abb6e55fb695d2f7bb308e5d7c2a44ffddf6b295a15c148167daaaf5cf34f586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff00000000000000000000000000000000";

    function run() public {
        // set up protocol

        vm.startBroadcast(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

        centralRegistry = new CentralRegistry(
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );
        master = new Master(address(centralRegistry));
        factory = new Factory(address(centralRegistry));
        leveragedNFT = new LeveragedNFT(address(centralRegistry));
        longQuoteOdosZerolend = new Long_Quote_Odos_Zerolend();
        longBaseOdosZerolend = new Long_Base_Odos_Zerolend();
        shortQuoteOdosZerolend = new Short_Quote_Odos_Zerolend();
        shortBaseOdosZerolend = new Short_Base_Odos_Zerolend();

        centralRegistry.addCore("MASTER", address(master));
        centralRegistry.addCore("FACTORY", address(factory));
        centralRegistry.addCore("LEVERAGE_NFT", address(leveragedNFT));
        centralRegistry.addProtocol("ODOS_ROUTER", OdosRouterAddress);
        centralRegistry.addProtocol("ZEROLEND_POOL", zeroLendAddress);
        centralRegistry.addImplementation(
            "LONG_QUOTE_ODOS_ZEROLEND",
            address(longQuoteOdosZerolend)
        );
        centralRegistry.addImplementation(
            "LONG_BASE_ODOS_ZEROLEND",
            address(longBaseOdosZerolend)
        );
        centralRegistry.addImplementation(
            "SHORT_QUOTE_ODOS_ZEROLEND",
            address(shortQuoteOdosZerolend)
        );
        centralRegistry.addImplementation(
            "SHORT_BASE_ODOS_ZEROLEND",
            address(shortBaseOdosZerolend)
        );

        vm.stopBroadcast();
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

interface WETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
