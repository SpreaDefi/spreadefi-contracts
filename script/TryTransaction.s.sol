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

    address WETHAddress = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;
    address masterAddress = 0xC76f1b20F72AE3B73376E035B54Ac3a97977d6B8;

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);


        bytes memory masterData = hex'07b1ea7100000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000100000000000000000000000000205edf0f225457fecfa22e5774e7a4c9177d56a80000000000000000000000000000000000000000000000000000000000000060000000000000000000000000176211869ca2b568f2a7d4ee941e073a821ee1ff000000000000000000000000e5d7c2a44ffddf6b295a15c148167daaaf5cf34f00000000000000000000000000000000000000000000000000000000000000174c4f4e475f424153455f4f444f535f5a45524f4c454e4400000000000000000000000000000000000000000000000000000000000000000000038d7ea4c6800000000000000000000000000000000000000000000000000000000000004a7ec2000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000d283bd37f90001176211869ca2b568f2a7d4ee941e073a821ee1ff0001e5d7c2a44ffddf6b295a15c148167daaaf5cf34f034a7ec207071cbb714818b4028f5c000156c85a254DD12eE8D9C04049a4ab62769Ce9821000000001637B76f670B6DE365Ad8D07E2F6F4908E7e24bDd0000000003010203000a0101010201ff000000000000000000000000000000000000000000586733678b9ac9da43dd7cb83bbb41d23677dfc3176211869ca2b568f2a7d4ee941e073a821ee1ff0000000000000000000000000000000000000000000000000000000000000000000000000000';
        
        masterAddress.call(masterData);

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
