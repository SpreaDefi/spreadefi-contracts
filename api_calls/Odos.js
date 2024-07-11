const axios = require('axios');

// The URL of the API endpoint
const url = 'https://api.odos.xyz/sor/quote/v2';

// The request body parameters
const requestBody = {
  chainId: 1, // Example Chain ID, replace with actual Chain ID
  inputTokens: [
    {
      tokenAddress: '0xTokenAddress1', // Replace with actual token address
      amount: '1000000000000000000' // Amount in fixed precision (example: 1 token with 18 decimals)
    }
  ],
  outputTokens: [
    {
      tokenAddress: '0xTokenAddress2', // Replace with actual token address
      proportion: 1 // Proportion for a single swap
    }
  ],
  gasPrice: '50000000000', // Optional: Gas price in wei (50 gwei example)
  userAddr: '0xYourWalletAddress', // Optional: User wallet address
  slippageLimitPercent: 0.5, // Optional: Slippage limit in percent
  sourceBlacklist: [], // Optional: List of liquidity providers to exclude
  sourceWhitelist: [], // Optional: List of liquidity providers to include exclusively
  poolBlacklist: [], // Optional: List of pool IDs to exclude
  pathVizImage: false, // Optional: Return a Base64 encoded SVG of path visualization image
  pathVizImageConfig: {}, // Optional: Customization parameters for the visualization image
  disableRFQs: true, // Optional: Disable RFQs
  referralCode: 'yourReferralCode', // Optional: Referral code
  compact: true, // Optional: Use compact call data
  likeAsset: false, // Optional: Route through like assets only
  simple: false // Optional: Simplify the quote
};

// Make the POST request to the API endpoint
axios.post(url, requestBody)
  .then(response => {
    // Handle the response data
    console.log(response.data);
  })
  .catch(error => {
    // Handle any errors
    console.error(`Failed to retrieve data: ${error}`);
  });
