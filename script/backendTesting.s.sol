// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "src/implementations/Long_Quote_Odos_Zerolend.sol";
import "src/Factory.sol";
import "src/CentralRegistry.sol";
import "src/Master.sol";
import "src/LeveragedNFT.sol";
import "src/interfaces/IMaster.sol";
import "src/interfaces/IERC721Receiver.sol";

contract BackendTesting is Script, IERC721Receiver {

    event debugAddress(string, address);
    event debugUint(string, uint);

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

    bytes getUSDC = hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff080de0b6b3a7640000048d92a68a028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce982100001DDed227D71A096c6B5D87807C1B5C456771aAA940001f39Fd6e51aad88F6F4ce6aB8827279cffFb92266000000000301020300100101000102ff000000000000000000000000000000000000000000dded227d71a096c6b5d87807c1b5c456771aaa94e5d7c2a44ffddf6b295a15c148167daaaf5cf34f000000000000000000000000000000000000000000000000";

    bytes odosAdd = hex"83bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0411e1a3000801bfd9aedcae9940028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce9821000000001c8c56cEe6AbC9b297C0f0Bd1cc6eE0E8F4e4fC61000000000c03050e012c4765c70a0102020301012f149ac40a0102040301011c5d47030a0102050301011dcdb3b10b020106030101bb7624b10b0300070301000a0400080301060a0201090a01080a02010b0c010210020100010dff00000000000000000095a849bf8613492241bcbda00c2e43af4f7888891d6cbd5ab95fcc04edde14abfa8d363adf4ead00176211869ca2b568f2a7d4ee941e073a821ee1ff0ab43d592f8fa273ce900d8749c854419e8e1459b59cb56330d1fc5c6240b8c7fc2dbeb09fd7a5dbe8190c17f5071b98e3d3ab1d6a8e711884e10d22b6e91ba27bb6c3b2adc31884459d3653f9293e33652c86ae02c9d01959c2b0da6867cfc542e98a1068594a53fc98eea213784534f44bcc08248b4e784af15ec2a0bd43db75dd04e62faa3b8ef36b00d51947b87d35e9f1cd53cede1ad6f7be44c12212b8a219439258ca9da29e9cc4ce5596924745e12b933aab2285ddcddad8edf438c1bab47e1a9d05a9b400000000000000000000000000000000000000000000000000000000";

    function run() public {

        // set up protocol

        vm.startBroadcast(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

        centralRegistry = new CentralRegistry(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
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

        // deposit ETH into WETH
        WETH(WETHAddress).deposit{value: 1 ether}();

        IERC20(WETHAddress).approve(address(OdosRouterAddress), type(uint256).max);

        // aquire quote token using odos
        OdosRouterAddress.call(getUSDC);

        // approve master to spend quote token
        IERC20(USDCAddress).approve(address(master), type(uint256).max);

        IMaster.NewPositionParams memory newPositionParams = IMaster.NewPositionParams({
            implementation: "LONG_QUOTE_ODOS_ZEROLEND",
            quoteToken: USDCAddress,
            baseToken: WETHAddress
        });

        (uint256 tokenId, address proxyAddress) = IMaster(address(master)).createPosition(newPositionParams);

        address proxyAddressCalled = leveragedNFT.tokenIdToProxy(tokenId);

        emit debugAddress("PROXY ADDRESS CHECK", proxyAddressCalled);

        emit debugAddress("proxyAddress", proxyAddress);
        emit debugUint("tokenId", tokenId);

        // approve master to spend tokens
        IERC20(USDCAddress).approve(address(master), type(uint256).max);

        IMaster.PositionParams memory positionAdd = IMaster.PositionParams({
            marginAmountOrCollateralReductionAmount: 100 * 10**6,
            flashLoanAmount: 200 * 10**6,
            pathDefinition: odosAdd
        });

        IMaster(address(master)).addToPosition(0, positionAdd);

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