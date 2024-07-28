const { ethers } = require('ethers');

// Connect to the Ethereum provider (e.g., Infura, Alchemy)
const provider = new ethers.providers.JsonRpcProvider('https://linea.decubate.com');

// Aave LendingPool contract address (mainnet example)
const lendingPoolAddress = '0x2f9bB73a8e98793e26Cb2F6C4ad037BDf1C6B269';

// ABI for the LendingPool contract (relevant parts only)
const lendingPoolAbi = [
  "function getReserveData(address asset) external view returns (tuple(uint256 configuration, ...))"
];

// Create a contract instance
const lendingPool = new ethers.Contract(lendingPoolAddress, lendingPoolAbi, provider);

// Address of the asset you want to check (e.g., DAI)
const assetAddress = '0x176211869cA2b568f2A7D4EE941E073a821EE1ff'; // DAI example

async function checkFlashLoanAvailability() {
  try {
    const reserveData = await lendingPool.getReserveData(assetAddress);
    const configuration = reserveData[0];

    // Extract flash loan availability from configuration
    const isFlashLoanEnabled = (configuration >> 30) & 1;

    if (isFlashLoanEnabled) {
      console.log('Flash loans are available for this asset.');
    } else {
      console.log('Flash loans are not available for this asset.');
    }
  } catch (error) {
    console.error('Error checking flash loan availability:', error);
  }
}

checkFlashLoanAvailability();
