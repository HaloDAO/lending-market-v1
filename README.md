[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

```
██╗  ██╗ █████╗ ██╗      ██████╗ ██████╗  █████╗  ██████╗
██║  ██║██╔══██╗██║     ██╔═══██╗██╔══██╗██╔══██╗██╔═══██╗
███████║███████║██║     ██║   ██║██║  ██║███████║██║   ██║
██╔══██║██╔══██║██║     ██║   ██║██║  ██║██╔══██║██║   ██║
██║  ██║██║  ██║███████╗╚██████╔╝██████╔╝██║  ██║╚██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝
```

# HaloDAO Lending Market V1

This repository contains the smart contracts source code and markets configuration for HaloDAO Lending Market. The repository uses Docker Compose and Hardhat as development enviroment for compilation, testing and deployment tasks.

## What is HaloDAO?

HaloDAO aims to incentivize and build asset-backed stablecoin liquidity by establishing the foundational money lego of DeFi. However, rather than using ETH or BTC to generate synthetic USD stablecoins as initial protocols have done, HaloDAO will;

- Build an Automated Market Maker (AMM) to enable efficient trades between stablecoins
- Build a Lending Market to allow more capital efficient lending and borrowing of stablecoins

One effect of launching two fundamental money legos under one protocol is the ability to replicate the early "recycling" of superfluid capital that contributed to the rapid rise of Total Value Locked (TVL) in DeFi. HaloDAO aims to replicate this behavior specifically for stablecoin liquidity.

## Documentation

Please check the latest documentation [here](https://docs.halodao.com/).

## Audits

- (pending)

## Connect with the community

You can join at the [Discord](https://discord.com/invite/halodao) channel or at the [Governance Forum](https://snapshot.org/#/halodao.eth) for asking questions about the protocol or talk about HaloDAO Lending Market with other peers.

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

The configurations related with the HaloDAO Lending Market Markets are located at `markets` directory. You can follow the `IAaveConfiguration` interface to create new Markets configuration or extend the current HaloDAO Lending Market configuration.

Each market should have his own Market configuration file, and their own set of deployment tasks, using the HaloDAO Lending Market market config and tasks as a reference.

## Test

You can run the full test suite with the following commands:

```
yarn test
```

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

You can deploy HaloDAO Lending Market in a forked Mainnet chain using Hardhat built-in fork feature:

```
docker-compose run contracts-env npm run aave:fork:main
```

### Deploy HaloDAO Lending Market into a Mainnet Fork via console with Docker

You can deploy HaloDAO Lending Market into the Hardhat console in fork mode, to interact with the protocol inside the fork or for testing purposes.

Run the console in Mainnet fork mode:

```
docker-compose run contracts-env npm run console:fork
```

At the Hardhat console, interact with the HaloDAO Lending Market protocol in Mainnet fork mode:

```
// Deploy the HaloDAO Lending Market protocol in fork mode
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

## Interact with HaloDAO Lending Market in Mainnet via console with Docker

You can interact with HaloDAO Lending Market at Mainnet network using the Hardhat console, in the scenario where the frontend is down or you want to interact directly. You can check the deployed addresses at https://docs.aave.com/developers/deployed-contracts.

Run the Hardhat console pointing to the Mainnet network:

```
docker-compose run contracts-env npx hardhat --network main console
```

At the Hardhat console, you can interact with the protocol:

```
// Load the HRE into helpers to access signers
run("set-DRE")

// Import getters to instance any HaloDAO Lending Market contract
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

[Refer to this document](https://halodao.atlassian.net/wiki/spaces/HALODAO/pages/169017345/Adding+New+Asset+using+script)
