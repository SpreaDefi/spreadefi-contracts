FORK_URL=https://linea.decubate.com

anvil --fork-url $FORK_URL --port 9001

forge test --fork-url http://localhost:9001 --match-contract "some test name" -vvvv

Assets available for flash loans:

"WETH", "USDC", "USDT", "ezETH"

Pairs to try:

wstETH / WETH