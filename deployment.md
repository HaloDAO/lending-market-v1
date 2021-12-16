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

3 - run `yarn run kovan:dev:halo:configure-incentives`

4 - run `yarn run kovan:dev:halo:deploy-uipooldataprovider`

# Deploying to Main Network

1 - run `yarn run hardhat halo:mainnet`

2 - change the incentives controller from `./markets/halo/commons.ts` (Line 271)

3 - run `yarn run mainnet:halo:configure-incentives`

4 - run `yarn run mainnet:halo:deploy-uipooldataprovider`

5 - run `yarn run hardhat --network mainnet deploy-UniswapLiquiditySwapAdapter` (to check)

6 - run `yarn run hardhat --network mainnet deploy-UniswapRepayAdapter`(to check)
