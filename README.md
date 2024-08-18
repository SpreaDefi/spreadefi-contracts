# Frontend Calculations

This is a guide to calculate required values for the frontend.

## Long Quote

Long Position is a position where you are long on the base token and short on the quote token.
You use the quote token as margin to borrow the base token.

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

Long Position is a position where you are long on the base token and short on the quote token.
You use the base token as margin and borrow more base token. The quote token is swapped for base token and the margin + swapped amount is used as collateral.

#### Add to Position
1. `tokenId` - the tokenid of the position NFT.
    #### Position Struct
    2. `marginAmountOrCollateralReductionAmount` - The amount of Base Token (volatile asset) to provide as margin.
    3. `flashLoanAmount` - The amount of quote token (stable asset) to borrow, this defines the amount of leverage a position has.
        > For example: 0.01 BTC is worth 100 USDC, using 200 USDC as flash loan amount, the position is 3x leveraged. 200 USDC is swapped for 0.02 BTC
    4. `pathDefinition` - the params needed to swap the flash loan amount for base token.

#### Remove from Position

1. `tokenId` - the tokenid of the position NFT
    #### Position Struct
    2. `marginAmountOrCollateralReductionAmount` - The amount of base token to unlock as collateral. The amount should be greater than the flashLoanAmount plus the interest (0.05%)
    3. `flashLoanAmount` - The amount of quote token to repay.
    4. `pathDefinition` - the params needed to swap the base token to quote token to repay the flash loan.

#### Close Position

1. `tokenId` - the tokenid of the position NFT
2. `pathDefinition` - the params needed to swap the base token to quote token to repay the flash loan.
    > The pathDefinition should swap all of the base token collateral to quote token to repay the flash loan+ interest and return the remaining quote token to the user.

## Short Quote

Short Position is a position where you are short on the base token and long on the quote token.
You use the quote token as margin. The base token is flash loaned. The flash loaned base token is swapped for quote token and used as collateral. The swapped quote token + margin is used as collateral. Base token is borrowed to repay the flash loan.

#### Add to position

1. `tokenId` - the tokenid of the position NFT.
    #### Position Struct
    2. `marginAmountOrCollateralReductionAmount` - The amount of quote token to provide as margin.
    3. `flashLoanAmount` - The amount of base token to borrow, this defines the amount of leverage a position has.
        > For example: 100 USDC as margin, 0.01 BTC is worth 100 USDC, 0.01 BTC is flash loaned, 0.01 BTC is swapped for 100 USDC, the position is 2x leveraged.
    4. `pathDefinition` - the params needed to swap the flash loan amount for quote token.

#### Remove from Position

1. `tokenId` - the tokenid of the position NFT
    #### Position Struct
    2. `marginAmountOrCollateralReductionAmount` - The amount of quote token to unlock as collateral. The amount should be greater than the flashLoanAmount plus the interest (0.05%)
    3. `flashLoanAmount` - The amount of base token to repay.
    4. `pathDefinition` - the params needed to swap the quote token to base token to repay the flash loan.