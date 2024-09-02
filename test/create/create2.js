const { ethers } = require('ethers');

// Replace with the actual values
const factoryAddress = "0xF62849F9A0B5Bf2913b396098F7c7019b51A820a"; // Address of the Factory contract
const toAddress0 = "0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496"; // Address of the recipient (_to)
const positionId0 = 0; // The current position ID for the recipient (_to)
const implementationAddress = "0xc7183455a4C133Ae270771860664b6B7ec320bB1"; // Address of the implementation contract

const positionId1 = 1; // The current position ID for the recipient (_to)


function predictAddress (_toAddress, _positionId, _implementationAddress)  {

    // Step 1: Calculate the salt
    const salt = ethers.utils.keccak256(
        ethers.utils.solidityPack(["address", "uint256"], [_toAddress, _positionId])
    );

    // Step 2: Compute the init code hash (bytecode + constructor args)
    const proxyBytecode = "0x60a060405234801561001057600080fd5b506040516101d43803806101d483398101604081905261002f9161009a565b6001600160a01b0381166100895760405162461bcd60e51b815260206004820152601e60248201527f496e76616c696420696d706c656d656e746174696f6e20616464726573730000604482015260640160405180910390fd5b6001600160a01b03166080526100ca565b6000602082840312156100ac57600080fd5b81516001600160a01b03811681146100c357600080fd5b9392505050565b60805160ec6100e860003960008181602001526055015260ec6000f3fe608060405260043610601c5760003560e01c80635c60da1b146045575b60437f00000000000000000000000000000000000000000000000000000000000000006093565b005b348015605057600080fd5b5060777f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200160405180910390f35b3660008037600080366000845af43d6000803e80801560b1573d6000f35b3d6000fdfea2646970667358221220f6020ed423ab8c3633806cc507ff73ce07ea9bade45f63874f1be7c04b23516364736f6c634300081a0033"; // Replace with the actual bytecode of the Proxy contract

    // Encode the constructor arguments (implementation address)
    const encodedConstructorArgs = ethers.utils.defaultAbiCoder.encode(["address"], [_implementationAddress]);


    const initCode = proxyBytecode + encodedConstructorArgs.slice(2);


    // Compute the init code hash
    const initCodeHash = ethers.utils.keccak256(initCode);


    // Step 3: Compute the contract address using CREATE2 formula
    const predictedAddress = ethers.utils.getCreate2Address(factoryAddress, salt, initCodeHash);

    return predictedAddress;

}

const predictedAddress0 = predictAddress(toAddress0, positionId0, implementationAddress);
console.log("predicted address 0: ",predictedAddress0);


const predictedAddress1 = predictAddress(toAddress0, positionId1, implementationAddress);
console.log("predicted address 1: ",predictedAddress1);