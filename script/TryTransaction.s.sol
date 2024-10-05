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

contract TryTransaction is Script, IERC721Receiver {
    address masterAddress = 0x0B306BF915C4d645ff596e518fAf3F9669b97016;

    bytes getUSDC =
        hex"83bd37f90001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0001176211869ca2b568f2a7d4ee941e073a821ee1ff080de0b6b3a7640000049dd7c067028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce9821000000001f39Fd6e51aad88F6F4ce6aB8827279cffFb922660000000007020308019481ce0c0a0101010200017060e6b00a010103020001b75b59d10a0200040200000a0200050200040a0101060700ff0000000000000000000000000064bccad8e7302e81b09894f56f6bba85ae82cd03e5d7c2a44ffddf6b295a15c148167daaaf5cf34f586733678b9ac9da43dd7cb83bbb41d23677dfc327ed78122b8ef363f4ef5b3afe197e0c4a2fa5141947b87d35e9f1cd53cede1ad6f7be44c12212b86e9ad0b8a41e2c148e7b0385d3ecbfdb8a216a9ba219439258ca9da29e9cc4ce5596924745e12b930000000000000000000000000000000000000000";

    bytes createAndAddCalldata =
        hex"211d9b04000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000060000000000000000000000000176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000e5d7c2a44ffddf6b295a15c148167daaaf5cf34f00000000000000000000000000000000000000000000000000000000000000184c4f4e475f51554f54455f4f444f535f5a45524f4c454e4400000000000000000000000000000000000000000000000000000000000000000000000005f5e1000000000000000000000000000000000000000000000000000000000011e1a300000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000d483bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f0417d7840008021845aa2b08c340028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000018EE06e608De47eA1b185583acA65E34F2fD79B130000000003010204018a874ab40a0101010201000a0101030201ff00000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff7077f0cff76077d0ebb335b607db57440051055700000000000000000000000000000000";

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    address OdosRouterAddress = 0x2d8879046f1559E53eb052E949e9544bCB72f414;

    address zeroLendAddress = 0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269;

    IERC20 usdc = IERC20(USDCAddress);
    IERC20 weth = IERC20(WETHAddress);

    function run() public {
        vm.startBroadcast(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

        // deposit ETH into WETH
        WETH(WETHAddress).deposit{value: 1 ether}();

        IERC20(WETHAddress).approve(
            address(OdosRouterAddress),
            type(uint256).max
        );

        // // aquire quote token using odos
        OdosRouterAddress.call(getUSDC);

        // approve master to spend quote token
        // IERC20(USDCAddress).approve(address(masterAddress), type(uint256).max);
        // IERC20(WETHAddress).approve(address(masterAddress), type(uint256).max);

        weth.approve(masterAddress, type(uint256).max);
        usdc.approve(masterAddress, type(uint256).max);

        masterAddress.call(createAndAddCalldata);

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
