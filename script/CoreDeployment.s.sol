// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "src/Factory.sol";
import "src/CentralRegistry.sol";
import "src/Master.sol";
import "src/LeveragedNFT.sol";
import "src/interfaces/IMaster.sol";
import "src/interfaces/IERC721Receiver.sol";
import "src/implementations/Long_Quote_Odos_Zerolend.sol";
import "src/implementations/Long_Base_Odos_Zerolend_Refactor.sol";
import "src/implementations/Short_Quote_Odos_Zerolend.sol";
import "src/implementations/Short_Base_Odos_Zerolend.sol";


contract CoreDeployment is Script {

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;
    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    // core contracts
    CentralRegistry centralRegistry;
    Master master;
    Factory factory;
    LeveragedNFT leveragedNFT;

    // first strategy implementations
    Long_Quote_Odos_Zerolend longQuoteOdosZerolend;
    Long_Base_Odos_Zerolend longBaseOdosZerolend;
    Short_Quote_Odos_Zerolend shortQuoteOdosZerolend;
    Short_Base_Odos_Zerolend shortBaseOdosZerolend;


    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerPublicKey = 0x205edf0f225457feCFA22e5774E7a4C9177d56A8;

        // set up protocol
        vm.startBroadcast(deployerPrivateKey);

        centralRegistry = new CentralRegistry(
            deployerPublicKey
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

}
