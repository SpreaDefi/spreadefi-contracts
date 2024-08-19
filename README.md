# Frontend Calculations

This is a guide to calculate required values for the frontend.

# Workflow
#### Creating and adding to position
In master, call `createAndAddToPosition` with the required params. The flash loaned amount will define the leverage of the position.

### Modifying the position
#### Increasing leverage
Using `addToPosition` - take a flash loan with the desired amount to increase the leverage. Use 0 as margin add. Should scale with the existing collateral.

*TODO: remove check that requires margin add to be zero*

Using `removeFromPosition` - dont flash loan anything which means you dont repay anything, just choose the amount of margin to remove

*TODO: add a case where the user enters bytes(0) into the path definition to not swap anything. need to add an if statement to check if the path definition is empty and not swap anything.*

#### Decreasing leverage
To add margin, we can deposit tokens into the zerolend lending pool on behalf of the proxy. This will reduce the leverage of the position. Another option is to add another function which just adds margin to the position.

To reduce the amount of the loan, we can use `removeFromPosition` with the desired amount of loan token to repay. And the corresponding amount of margin to unlock that matches the amount of loan token to repay.

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