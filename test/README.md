FORK_URL=https://linea.decubate.com

anvil --fork-url $FORK_URL --port 9001

forge test --fork-url http://localhost:9001 --match-contract "some test name" -vvvv


## Notes for testing
#### For testing Long Base
1. when adding to positions, get the USDC price of the base token to borrow
2. when removing from positions, get the amount of WBTC you want to sell, make sure it covers
the entire flash loan debt + premium
3. When closing positions, make sure to get the amount of WBTC you want to sell (total debt - margin provided), it must be as close to the flash loaned amount as possible or else you will receive more USDC instead of base token.