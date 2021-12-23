# Prerequisite

1 - run `yarn && yarn compile`

2 - grab `deployed-contracts.json` from 1password & paste on root dir

# Deploying to localhost

1 - run `yarn run hardhat node`

2 - on a new terminal, run `yarn run localhost:dev:halo`

## Testing

```
yarn run external:lendingpool-action
  --network localhost
  --action deposit // mintToken | approveToken | deposit | borrow | repay | withdraw
  --amount 100 // 0 when calling a get function
```

# Deploying to Kovan

1 - run `yarn run kovan:dev:halo`

2 - change the `IncentivesController` address in `./markets/halo/commons.ts` (Line 269)

- get address from `deployed-contracts.json` > `RnbwIncentivesController`

3 - change atoken addresses by calling `getReservesData`

4 - change all contracts in `/markets/halo/common.ts`: LendingRateOracle, LendingPoolCollateralManager, LendingPoolConfigurator, LendingPool, WethGateway, AaveOracle, WETH, ReserveFactorTreasuryAddress, IncentivesController

4 - run `yarn run kovan:dev:halo:configure-incentives`

5 - run `yarn run kovan:dev:halo:deploy-uipooldataprovider`

# Deploying to Main Network

### Main Deployment

1 - Deploy addresses provider, execute `yarn hardhat halo:mainnet-1 --network mainnet --verify`

2 - Deploy lending pool, execute `yarn hardhat halo:mainnet-2 --network mainnet --verify`

3 - Deploy oracles, execute `yarn hardhat halo:mainnet-3 --network mainnet --verify`

4 - Deploy WETH Gateway, execute `yarn hardhat halo:mainnet-4 --network mainnet --verify`

5 - Change WETHGateway in`./markets/halo/commons.ts` (Line 143)

6 - Initialize contracts, execute `yarn run hardhat halo:mainnet-5 --network mainnet --verify`

7 - Deploy UI Provider Contracts, execute `yarn run hardhat halo:mainnet-6 --network mainnet --verify`

### (Optional) for now

8 - run `yarn run hardhat --network mainnet deploy-UniswapLiquiditySwapAdapter` (to check)

9 - run `yarn run hardhat --network mainnet deploy-UniswapRepayAdapter`(to check)

10 - change the incentives controller from `./markets/halo/commons.ts` (Line 271)

11 - Configure Incentives, run `yarn run mainnet:halo:configure-incentives`
