const axios = require('axios');

// The URL of the API endpoint
const url = 'https://api.odos.xyz/sor/quote/v2';

// Token addresses and Chain ID
const USDCAddress = "0x176211869cA2b568f2A7D4EE941E073a821EE1ff";
const WETHAddress = "0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f";
const chainId = 59144; // Replace with the actual Chain ID if different

// The request body parameters with only required fields
const requestBody = {
  chainId: chainId,
  inputTokens: [
    {
      tokenAddress: USDCAddress, // USDC address
      amount: '10000000' // Amount in fixed precision (example: 10 USDC with 6 decimals)
    }
  ],
  outputTokens: [
    {
      tokenAddress: WETHAddress, // WETH address
      proportion: 1 // Proportion for a single swap
    }
  ]
};

// Set headers if required by the API (example)
const headers = {
  'Content-Type': 'application/json'
};

// Make the POST request to the API endpoint
axios.post(url, requestBody, { headers: headers })
  .then(response => {
    // Handle the response data
    console.log(response.data);
  })
  .catch(error => {
    // Handle any errors
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      console.error('Error response:', error.response.data);
      console.error('Error status:', error.response.status);
      console.error('Error headers:', error.response.headers);
    } else if (error.request) {
      // The request was made but no response was received
      console.error('Error request:', error.request);
    } else {
      // Something happened in setting up the request that triggered an Error
      console.error('Error message:', error.message);
    }
    console.error('Error config:', error.config);
  });
