const axios = require('axios');

// Addresses for tokens (USDC and WETH)
const USDCAddress = "0x176211869cA2b568f2A7D4EE941E073a821EE1ff";
const WETHAddress = "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f";
const LineaChainId = 59144;
const userAddr = '0x4f81992FCe2E1846dD528eC0102e6eE1f61ed3e2'; // Replace with the correct address

// Function to get the quote and pathId
async function getQuote() {
    const url = 'https://api.odos.xyz/sor/quote/v2';
    const requestBody = {
        chainId: LineaChainId,
        inputTokens: [
            {
                tokenAddress: WETHAddress,
                amount: '1000000000000000' 
            }
        ],
        outputTokens: [
            {
                tokenAddress: USDCAddress,
                proportion: 1
            }
        ],
        slippageLimitPercent: 1,
        userAddr: userAddr
    };

    try {
        const response = await axios.post(url, requestBody);
        console.log('Quote Response:', response.data);
        if (response.data.pathId) {
            console.log('outAmounts:', response.data.outAmounts);
            return response.data.pathId;
        } else {
            console.error('No pathId returned in the quote response');
            return null;
        }
    } catch (error) {
        console.error('Failed to retrieve quote data:', error);
        return null;
    }
}

// Function to assemble the transaction using pathId
async function assembleTransaction(pathId) {
    const url = 'https://api.odos.xyz/sor/assemble';
    const requestBody = {
        userAddr: userAddr, // Ensure this is the address used to generate the quote
        pathId: pathId,
        simulate: false, // Optional, set to true if you want to simulate the transaction first
        receiver: userAddr // Optional, specify a different receiver address for the transaction output
    };

    try {
        const response = await axios.post(url, requestBody);
        console.log('Assemble Response:', response.data);
        if (response.data.transaction && response.data.transaction.data) {
            return response.data.transaction.data;
        } else {
            console.error('No transaction data returned in the assemble response');
            return null;
        }
    } catch (error) {
        if (error.response) {
            console.error('Error response data:', JSON.stringify(error.response.data, null, 2));
            console.error('Error status:', error.response.status);
            console.error('Error headers:', JSON.stringify(error.response.headers, null, 2));
        } else if (error.request) {
            console.error('Error request:', error.request);
        } else {
            console.error('Error message:', error.message);
        }
        console.error('Error config:', JSON.stringify(error.config, null, 2));
        return null;
    }
}

// Main function to get quote and assemble transaction with detailed logging
async function main() {
    const pathId = await getQuote();
    if (pathId) {
        console.log(`Path ID: ${pathId}`);
        const transactionData = await assembleTransaction(pathId);
        if (transactionData) {
            console.log(`Transaction Data: ${transactionData}`);
        } else {
            console.log('Failed to retrieve transaction data.');
        }
    } else {
        console.log('Failed to retrieve path ID.');
    }
}

// Execute the main function
main();
