# Frontend Calculations

This is a guide to calculate required values for the frontend.

## Long Quote

Long Position is a position where you are long on the base token and short on the quote token.

#### Add to Position
1. `tokenId` - the tokenid of the position NFT.
    #### Position Struct
    2. `marginAmountOrCollateralReductionAmount` - The amount of Quote (stable asset) to provide as margin.
    3. `flashLoanAmount` - The amount of Quote (stable asset) to borrow, this defines the amount of leverage a position has.
        > For example: 100 USDC as margin, using 200 USDC as flash loan amount, the position is 3x leveraged.
    4. `pathDefinition` - The params needed for the swap or raw transaction data.

#### Remove from Position

1. `tokenId` - the tokenid of the position NFT
    #### Position Struct
    2. `marginAmountOrCollateralReductionAmount` - The amount of Base Token (volatile asset) to withdraw from the position as collateral.
    3. `flashLoanAmount` - The amount of Quote (stable asset) to repay, marginAmountOrCollateralReductionAmount quote value should be greater than the flashLoanAmount plus the interest (0.05%)
    4. `pathDefinition` - The params needed for the swap or raw transaction data.

#### Close Position

1. `tokenId` - the tokenid of the position NFT
2. `pathDefinition` - The params needed for the swap or raw transaction data.
    > The pathDefinition should swap all of the base token collateral to quote token to repay the flash loan+ interest and return the remaining quote token to the user.


## Long Base