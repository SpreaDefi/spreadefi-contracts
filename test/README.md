FORK_URL=https://linea-mainnet.infura.io/v3/53170927972f40d3850a6f0dd18a1324

anvil --fork-url $FORK_URL --port 9001

forge test --fork-url http://localhost:9001 --match-contract "some test name" -vvvv

Assets available for flash loans:

"WETH", "USDC", "USDT", "ezETH"

Pairs to try:

wstETH / WETH