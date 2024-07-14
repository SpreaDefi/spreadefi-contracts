FORK_URL=https://linea.decubate.com

anvil --fork-url $FORK_URL --port 9001

forge test --fork-url http://localhost:9001 --match-contract "some test name" -vvvv


If using Odos,
Update the user address in odos.js