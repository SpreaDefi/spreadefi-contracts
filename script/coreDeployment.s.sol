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

    bytes getUSDC = hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff080de0b6b3a7640000049045517b028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce9821000000001f39Fd6e51aad88F6F4ce6aB8827279cffFb92266000000000d04050f0119d1f2010801010102011dc727940a0101030200015716e4b61001010104020118a6431108020005020192d901820a020006020001d09128f40a0300070200000a0400080200080a0101090a00040a01010b0c00060a01010d0e00ff00000000000000000000000000000000000000000000000000000000000000005ec5b1e9b1bd5198343abb6e55fb695d2f7bb308e5d7c2a44ffddf6b295a15c148167daaaf5cf34f7077f0cff76077d0ebb335b607db574400510557dded227d71a096c6b5d87807c1b5c456771aaa948aebffb3964ec5cea0915080ddc1aca079583a4d8611456f845293edd3f5788277f00f7c05ccc29168594a53fc98eea213784534f44bcc08248b4e785afda31027c3e6a03c77a113ffc031b564abbf051d6cbd5ab95fcc04edde14abfa8d363adf4ead003aab2285ddcddad8edf438c1bab47e1a9d05a9b4efd5ec2cc043e3bd3c840f7998cc42ee712700baa219439258ca9da29e9cc4ce5596924745e12b93a48e0630b7b9dcb250112143c9d0fe47d26cb1e44af15ec2a0bd43db75dd04e62faa3b8ef36b00d50000000000000000";

    function run() public {

        // set up protocol

        vm.startBroadcast(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

        centralRegistry = new CentralRegistry(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
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
        centralRegistry.addImplementation("LONG_QUOTE_ODOS_ZEROLEND", address(longQuoteOdosZerolend));
        centralRegistry.addImplementation("LONG_BASE_ODOS_ZEROLEND", address(longBaseOdosZerolend));
        centralRegistry.addImplementation("SHORT_QUOTE_ODOS_ZEROLEND", address(shortQuoteOdosZerolend));
        centralRegistry.addImplementation("SHORT_BASE_ODOS_ZEROLEND", address(shortBaseOdosZerolend));

        // deposit ETH into WETH
        WETH(WETHAddress).deposit{value: 10 ether}();

        IERC20(WETHAddress).approve(address(OdosRouterAddress), type(uint256).max);

        // aquire quote token using odos
        OdosRouterAddress.call(getUSDC);

        // approve master to spend tokens
        IERC20(USDCAddress).approve(address(master), type(uint256).max);

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