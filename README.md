[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

```
██╗  ██╗ █████╗ ██╗      ██████╗ ██████╗  █████╗  ██████╗
██║  ██║██╔══██╗██║     ██╔═══██╗██╔══██╗██╔══██╗██╔═══██╗
███████║███████║██║     ██║   ██║██║  ██║███████║██║   ██║
██╔══██║██╔══██║██║     ██║   ██║██║  ██║██╔══██║██║   ██║
██║  ██║██║  ██║███████╗╚██████╔╝██████╔╝██║  ██║╚██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝
```

# Xave Finance Lending Market

This repository contains the smart contracts source code and markets configuration for Xave Finance Lending Market. The repository uses Docker Compose and Hardhat as development enviroment for compilation, testing and deployment tasks.

## What is Xave Finance?

Xave Finance aims to incentivize and build asset-backed stablecoin liquidity by establishing the foundational money lego of DeFi. However, rather than using ETH or BTC to generate synthetic USD stablecoins as initial protocols have done, Xave Finance will;

- Build an Automated Market Maker (AMM) to enable efficient trades between stablecoins
- Build a Lending Market to allow more capital efficient lending and borrowing of stablecoins

One effect of launching two fundamental money legos under one protocol is the ability to replicate the early "recycling" of superfluid capital that contributed to the rapid rise of Total Value Locked (TVL) in DeFi. Xave Finance aims to replicate this behavior specifically for stablecoin liquidity.

## Documentation

Please check the latest documentation [here](https://docs.xave.co/).

## Audits

- (pending)

## Getting Started

Ensure you are using the correct node version. In the root directory execute the following:

```sh
# nvm will install and use the version specified in .nvmrc file
nvm install
nvm use
```

You can install `@aave/protocol-v2` as an NPM package in your Hardhat, Buidler or Truffle project to import the contracts and interfaces:

`npm install @aave/protocol-v2`

Import at Solidity files:

```
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";

contract Misc {

  function deposit(address pool, address token, address user, uint256 amount) public {
    ILendingPool(pool).deposit(token, amount, user, 0);
    {...}
  }
}
```

The JSON artifacts with the ABI and Bytecode are also included into the bundled NPM package at `artifacts/` directory.

Import JSON file via Node JS `require`:

```
const LendingPoolV2Artifact = require('@aave/protocol-v2/artifacts/contracts/protocol/lendingpool/LendingPool.sol/LendingPool.json');

// Log the ABI into console
console.log(LendingPoolV2Artifact.abi)
```

## Setup

- Create an enviroment file named `.env` and fill the next enviroment variables

```
# Mnemonic, only first address will be used
MNEMONIC=""

# Add Alchemy or Infura provider keys, alchemy takes preference at the config level
ALCHEMY_KEY=""
INFURA_KEY=""


# Optional Etherscan key, for automatize the verification of the contracts at Etherscan
ETHERSCAN_KEY=""

# Optional, if you plan to use Tenderly scripts
TENDERLY_PROJECT=""
TENDERLY_USERNAME=""

```

## Local Setup

- This repo eliminates docker implementation from Aave and uses hardhat instead for faster setup.
- You can either run a node for localhost config by running `yarn hardhat node` on one terminal then add `--network localhost` on all hardhat tasks that youy will execute. You can also run tasks using the temporary hardhat node by not adding a flag for network and just running the task.

## Markets configuration

The configurations related with the Xave Finance Lending Market Markets are located at `markets` directory. You can follow the `IAaveConfiguration` interface to create new Markets configuration or extend the current Xave Finance Lending Market configuration.

Each market should have his own Market configuration file, and their own set of deployment tasks, using the Xave Finance Lending Market market config and tasks as a reference.

## Test

You can run the full test suite with the following commands:

```
yarn test
```

NOTES:

- You can use a non forked version of the hardhat node to run this in an isolated environment (which is preferred). Refer to the comments on `./hardhat.config.ts` in the `buidlerConfig.networks.hardhat`
- Test may fail when the test engine runs incentives controller tests. Sometimes its off by 1. Just run the test again.

### Local Deployment

1. In one terminal: `yarn hardhat node`
2. In another terminal, generate typechain types first by running `yarn hardhat compile`
3. You can now deploy the whole environment in your local node. Run `yarn hardhat halo:dev --withmocktokens true` (this installs mock tokens for local dev environment, if you want to read from your previously generated `deployed-contracts.json` file then set this to false)

### Kovan deployment

1. If you made any changes from the smart contracts, make sure to recompile them first since some deplyment scripts skips compiling. Run `yarn recompile`
2. Make sure you have the updated Kovan assets in the `markets` directory on kovan
3. Deploy the whole environment to Kovan by running `yarn hardhat halo:dev --withmocktokens false --network kovan`
4. Test using the tasks in `Lending Pool Tasks`

### Mainnet fork deployment via Docker

You can deploy Xave Finance Lending Market in a forked Mainnet chain using Hardhat built-in fork feature:

```
docker-compose run contracts-env npm run aave:fork:main
```

### Deploy Xave Finance Lending Market into a Mainnet Fork via console with Docker

You can deploy Xave Finance Lending Market into the Hardhat console in fork mode, to interact with the protocol inside the fork or for testing purposes.

Run the console in Mainnet fork mode:

```
docker-compose run contracts-env npm run console:fork
```

At the Hardhat console, interact with the Xave Finance Lending Market protocol in Mainnet fork mode:

```
// Deploy the Xave Finance Lending Market protocol in fork mode
await run('aave:mainnet')

// Or your custom Hardhat task
await run('your-custom-task');

// After you initialize the HRE via 'set-DRE' task, you can import any TS/JS file
run('set-DRE');

// Import contract getters to retrieve an Ethers.js Contract instance
const contractGetters = require('./helpers/contracts-getters'); // Import a TS/JS file

// Lending pool instance
const lendingPool = await contractGetters.getLendingPool("LendingPool address from 'aave:mainnet' task");

// You can impersonate any Ethereum address
await network.provider.request({ method: "hardhat_impersonateAccount",  params: ["0xb1adceddb2941033a090dd166a462fe1c2029484"]});

const signer = await ethers.provider.getSigner("0xb1adceddb2941033a090dd166a462fe1c2029484")

// ERC20 token DAI Mainnet instance
const DAI = await contractGetters.getIErc20Detailed("0x6B175474E89094C44Da98b954EedeAC495271d0F");

// Approve 100 DAI to LendingPool address
await DAI.connect(signer).approve(lendingPool.address, ethers.utils.parseUnits('100'));

// Deposit 100 DAI
await lendingPool.connect(signer).deposit(DAI.address, ethers.utils.parseUnits('100'), await signer.getAddress(), '0');

```

## Interact with Xave Finance Lending Market in Mainnet via console with Docker

You can interact with Xave Finance Lending Market at Mainnet network using the Hardhat console, in the scenario where the frontend is down or you want to interact directly. You can check the deployed addresses at https://docs.aave.com/developers/deployed-contracts.

Run the Hardhat console pointing to the Mainnet network:

```
docker-compose run contracts-env npx hardhat --network main console
```

At the Hardhat console, you can interact with the protocol:

```
// Load the HRE into helpers to access signers
run("set-DRE")

// Import getters to instance any Xave Finance Lending Market contract
const contractGetters = require('./helpers/contracts-getters');

// Load the first signer
const signer = await contractGetters.getFirstSigner();

// Lending pool instance
const lendingPool = await contractGetters.getLendingPool("0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9");

// ERC20 token DAI Mainnet instance
const DAI = await contractGetters.getIErc20Detailed("0x6B175474E89094C44Da98b954EedeAC495271d0F");

// Approve 100 DAI to LendingPool address
await DAI.connect(signer).approve(lendingPool.address, ethers.utils.parseUnits('100'));

// Deposit 100 DAI
await lendingPool.connect(signer).deposit(DAI.address, ethers.utils.parseUnits('100'), await signer.getAddress(), '0');
```

## Using lending pool tasks (if using hardhat environment)

Run the following command to test lending pool related tasks
`yarn/npm run hardhat external:lendingpool-action --action {desired action} --amount {amount to use, 0 if getter functions}

list of actions

- `approveToken` - approve token spend to the lending market
- `mintToken` - mint more of test tokens
- `deposit` - deposit in lending market with the --amount parameter value as amount
- `withdraw` - withdraw in lending market with the --amount parameter value as amount
- `borrow` - borrow in lending market with the --amount parameter value as amount
- `repay` - repay in lending market with the --amount parameter value as amount
- `getUserReserveData` - get user's reserve data
- `getReservesList` - get all reserves list
- `setUserUseReserveAsCollateral` - set current hardcoded asset as a collateral for borrow

note: you can modify the `TEST_ASSET` if you want to use other tokens, default now is USDC
note 2: check the addresses especially when running localhost node

## Adding a new asset in the market

[Refer to this document](https://Xave Finance.atlassian.net/wiki/spaces/Xave Finance/pages/169017345/Adding+New+Asset+using+script)

## Disable borrowing asset

Run `yarn hardhat external:disable-borrow-reserve --symbol {symbol of the asset} --lp {if it's an lp token}`

## Foundry Script deployments and testing

Local deployment development and testing:

```sh
# start a fork of AVAX with anvil
yarn run anvil:avax

# in another terminal run the deployment script in watch more, pointing at the local anvil node
yarn run watch:script-local
```

## Full Market Deployment With Foundry

0 - Prepare the folder of the network in the markets folder. name the folder as `xave-{network}` and new tasks per network based on the previous deployments.

1 - Import deployer 2 mnemonic inside cast.

```sh
# assuming you've imported a private key with cast wallet as such
# foundry will **encrypt** and store the private key in
# ~/.foundry/keystores/MY_DEPLOYER_WALLET
cast wallet import "MY_DEPLOYER_WALLET" --interactive

```

2 - Make or edit the `deployments/xave_oracles_config.{network}.json`
Get all required USD oracles pair tokens and LP tokens inside the config

3 - Deploy all required oracles.

```sh
# deploy Xave Oracles for the Lending Market
# NB: notice the last "sepolia" value which is the network value passed into the `run` method
forge script script/XaveOraclesDeployment.s.sol:XaveOraclesDeployment --sig "run(string memory network)" --slow --account "MY_DEPLOYER_WALLET" --broadcast --rpc-url "${NETWORK_RPC_URL}" -vvv sepolia

```

Add all newly deployed oracles in commons.ts under ChainlinkAggregator

4 - Generate `lending_market_config.network.json` by running the command

```sh
yarn hardhat xave:avax-deployment-config
```

Remove all the " on the numbers by finding using the regex mode `"(\d+)"` and replacing it with `$1`

5 - deploy lending market

```sh
# deploy lending market
source .env && forge script script/LendingPoolDeployment.s.sol:LendingPoolDeployment --slow --account "MY_DEPLOYER_WALLET" --broadcast -vvv --rpc-url "${SEPOLIA_RPC_URL}"


# or
# the ff address is deployer 2
# network - is the network to deploy so we can access json config


forge script script/LendingPoolDeployment.s.sol:LendingPoolDeployment --sig "run(string memory network)" --slow --account 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd --broadcast --rpc-url "RPC_URL" -vvv {network}
```
