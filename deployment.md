# Deploying to localhost

1 - run `yarn run hardhat node`
2 - run `yarn run localhost:dev:halo`
3 - you can test using `yarn run external:lendingpool-action --network localhost --action {mintToken => approveToken => deposit => borrow => repay => withdraw} --amount {0 when calling a get function}`

# Deploying to Kovan

1 - run `yarn run kovan:dev:halo`
2 - change the incentives controller from `./markets/halo/commons.ts` (Line 269)
3 - run `yarn run kovan:dev:halo:configure-incentives`
4 - run `yarn run kovan:dev:halo:deploy-uipooldataprovider`

# Deploying to Main Network

1 - run `yarn run hardhat halo:mainnet`
2 - change the incentives controller from `./markets/halo/commons.ts` (Line 271)
3 - run `yarn run mainnet:halo:configure-incentives`
4 - run `yarn run mainnet:halo:deploy-uipooldataprovider`
5 - run `yarn run hardhat --network mainnet deploy-UniswapLiquiditySwapAdapter` (to check)
6 - run `yarn run hardhat --network mainnet deploy-UniswapRepayAdapter`(to check)
