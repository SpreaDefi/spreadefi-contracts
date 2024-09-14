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

    bytes createAndAddCalldata = hex'0e8261130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000d483bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f040beea7fe080125c5f22c29b630028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce98210000000019d1794bAb9664C755eD74a7d44f3da02A5613DF40000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000000000000000000000000000000000000000000000000000';

    address USDCAddress = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;

    IERC20 usdc = IERC20(USDCAddress);
    IERC20 weth = IERC20(WETHAddress);

    function run() public {

        vm.startBroadcast(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

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