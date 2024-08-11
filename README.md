0. run `anvil`
im using the first provided public/private address for deployments and testing

## 1. deploy stakingLibrary

command: forge create src/LibStakingStorage.sol:LibStakingStorage --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Result:  0x5FbDB2315678afecb367f032d93F642f64180aa3

## 2. deploy StakingViewsFacet

command: forge create src/MockStakingViewsFacet.sol:StakingViewsFacet --libraries src/LibStakingStorage.sol:LibStakingStorage:0x5FbDB2315678afecb367f032d93F642f64180aa3 --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 
Result: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

## 3. deploy StakingBalancesFacet with StakingViewsFacet address as constructor argument

 command: forge create src/MockStakingBalancesFacet.sol:StakingBalancesFacet --constructor-args 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 --libraries src/LibStakingStorage.sol:LibStakingStorage:0x5FbDB2315678afecb367f032d93F642f64180aa3 --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 
result: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0

## 4. deploy StakingBalancesViewsFacet

command: forge create src/MockStakingBalancesViewsFacet.sol:StakingBalancesViewsFacet --libraries src/LibStakingStorage.sol:LibStakingStorage:0x5FbDB2315678afecb367f032d93F642f64180aa3 --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

result: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9

## 5. deploy StakingManager in test script with previousyl deployed addresses
command: forge test --fork-url http://127.0.0.1:8545


