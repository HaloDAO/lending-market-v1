import { task } from 'hardhat/config';

import { getXaveDeploymentDb, waitForTx } from '../../helpers/misc-utils';
import { XaveSepoliaConfig } from '../../markets/xave-sepolia';
import { eEthereumNetwork } from '../../helpers/types';

type ReserveValue = {
  tokenReserve: string;
  tokenAddress: string;
  baseLTVAsCollateral: string;
  liquidationThreshold: string;
  liquidationBonus: string;
  borrowingEnabled: string;
  stableBorrowRateEnabled: string;
  reserveDecimals: string;
  aTokenImpl: string;
  reserveFactor: string;
};

type RateStrategy = {
  name: string;
  tokenReserve: string;
  tokenAddress: string;
  optimalUtilizationRate: string;
  baseVariableBorrowRate: string;
  variableRateSlope1: string;
  variableRateSlope2: string;
  stableRateSlope1: string;
  stableRateSlope2: string;
};

task('xave:sepolia-deployment-config', 'Export used config').setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');

  const tokens: string[] = ['USDC', 'XSGD', 'LP_XSGD_USDC'];

  let reserveValue: ReserveValue[] = [];
  let rateStrategy: RateStrategy[] = [];
  let borrowRates: any[] = [];

  for (var token of tokens) {
    console.log(`Writing for ${token}`);

    reserveValue.push({
      aTokenImpl: XaveSepoliaConfig.ReservesConfig[`${token}`].aTokenImpl,
      baseLTVAsCollateral: XaveSepoliaConfig.ReservesConfig[`${token}`].baseLTVAsCollateral,
      borrowingEnabled: XaveSepoliaConfig.ReservesConfig[`${token}`].borrowingEnabled,
      liquidationBonus: XaveSepoliaConfig.ReservesConfig[`${token}`].liquidationBonus,
      liquidationThreshold: XaveSepoliaConfig.ReservesConfig[`${token}`].liquidationThreshold,
      reserveDecimals: XaveSepoliaConfig.ReservesConfig[`${token}`].reserveDecimals,
      reserveFactor: XaveSepoliaConfig.ReservesConfig[`${token}`].reserveFactor,
      stableBorrowRateEnabled: XaveSepoliaConfig.ReservesConfig[`${token}`].stableBorrowRateEnabled,
      tokenAddress: XaveSepoliaConfig.ReserveAssets[eEthereumNetwork.sepolia][`${token}`],
      tokenReserve: token,
    });

    rateStrategy.push({
      baseVariableBorrowRate: XaveSepoliaConfig.ReservesConfig[`${token}`].strategy.baseVariableBorrowRate,
      name: XaveSepoliaConfig.ReservesConfig[`${token}`].strategy.name,
      optimalUtilizationRate: XaveSepoliaConfig.ReservesConfig[`${token}`].strategy.optimalUtilizationRate,
      stableRateSlope1: XaveSepoliaConfig.ReservesConfig[`${token}`].strategy.stableRateSlope1,
      stableRateSlope2: XaveSepoliaConfig.ReservesConfig[`${token}`].strategy.stableRateSlope2,
      tokenAddress: XaveSepoliaConfig.ReserveAssets[eEthereumNetwork.sepolia][`${token}`],
      tokenReserve: token,
      variableRateSlope1: XaveSepoliaConfig.ReservesConfig[`${token}`].strategy.variableRateSlope1,
      variableRateSlope2: XaveSepoliaConfig.ReservesConfig[`${token}`].strategy.variableRateSlope2,
    });

    borrowRates.push(XaveSepoliaConfig.LendingRateOracleRatesCommon[`${token}`].borrowRate);
  }
  await getXaveDeploymentDb('sepolia').set('borrowRates', borrowRates).write();
  await getXaveDeploymentDb('sepolia').set(`marketId`, XaveSepoliaConfig.MarketId).write();
  await getXaveDeploymentDb('sepolia').set('rateStrategy', rateStrategy).write();
  await getXaveDeploymentDb('sepolia').set('reserveConfigs', reserveValue).write();
});
