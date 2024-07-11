const axios = require('axios');

// Addresses for tokens (USDC and WETH)
const USDCAddress = "0x176211869cA2b568f2A7D4EE941E073a821EE1ff";
const WETHAddress = "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f";
const LineaChainId = 59144;
const userAddr = '0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496'; // Replace with the correct address

// Function to get the quote and pathId
async function getQuote() {
    const url = 'https://api.odos.xyz/sor/quote/v2';
    const requestBody = {
        chainId: LineaChainId,
        inputTokens: [
            {
                tokenAddress: USDCAddress,
                amount: '300000000' // Amount in smallest unit (e.g., wei for ETH)
            }
        ],
        outputTokens: [
            {
                tokenAddress: WETHAddress,
                proportion: 1
            }
        ],
        userAddr: userAddr // Include user address in the quote request
    };

    try {
        const response = await axios.post(url, requestBody);
        console.log('Quote response:', response.data);
        return response.data.pathId;
    } catch (error) {
        console.error('Failed to retrieve data:', error);
        return null;
    }
}

// Function to assemble the transaction using pathId
async function assembleTransaction(pathId) {
    const url = 'https://api.odos.xyz/sor/assemble';
    const requestBody = {
        userAddr: userAddr, // Ensure this is the address used to generate the quote
        pathId: pathId,
        simulate: false
    };

    try {
        const response = await axios.post(url, requestBody);
        console.log('Assemble response:', response.data); // Print full response for debugging
        return response.data.transaction.data;
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
        const pathDefinition = await assembleTransaction(pathId);
        if (pathDefinition) {
            console.log(`Path Definition: ${pathDefinition}`);
        } else {
            console.log('Failed to retrieve path definition.');
        }
    } else {
        console.log('Failed to retrieve path ID.');
    }
}

// Execute the main function
main();
