import { task } from 'hardhat/config';

import { getXaveDeploymentDb, waitForTx } from '../../helpers/misc-utils';
import { XaveAvalancheConfig } from '../../markets/xave-avax';
import { eAvalancheNetwork } from '../../helpers/types';

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

task('xave:avax-deployment-config', 'Export used config').setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');

  const tokens: string[] = ['USDC', 'EUROC', 'VCHF', 'VEUR', 'LP_EUROC_USDC', 'LP_VEUR_USDC', 'LP_VCHF_USDC'];

  let reserveValue: ReserveValue[] = [];
  let rateStrategy: RateStrategy[] = [];
  let borrowRates: any[] = [];

  for (var token of tokens) {
    console.log(`Writing for ${token}`);

    reserveValue.push({
      aTokenImpl: XaveAvalancheConfig.ReservesConfig[`${token}`].aTokenImpl,
      baseLTVAsCollateral: XaveAvalancheConfig.ReservesConfig[`${token}`].baseLTVAsCollateral,
      borrowingEnabled: XaveAvalancheConfig.ReservesConfig[`${token}`].borrowingEnabled,
      liquidationBonus: XaveAvalancheConfig.ReservesConfig[`${token}`].liquidationBonus,
      liquidationThreshold: XaveAvalancheConfig.ReservesConfig[`${token}`].liquidationThreshold,
      reserveDecimals: XaveAvalancheConfig.ReservesConfig[`${token}`].reserveDecimals,
      reserveFactor: XaveAvalancheConfig.ReservesConfig[`${token}`].reserveFactor,
      stableBorrowRateEnabled: XaveAvalancheConfig.ReservesConfig[`${token}`].stableBorrowRateEnabled,
      tokenAddress: XaveAvalancheConfig.ReserveAssets[eAvalancheNetwork.avalanche][`${token}`],
      tokenReserve: token,
    });

    rateStrategy.push({
      baseVariableBorrowRate: XaveAvalancheConfig.ReservesConfig[`${token}`].strategy.baseVariableBorrowRate,
      name: XaveAvalancheConfig.ReservesConfig[`${token}`].strategy.name,
      optimalUtilizationRate: XaveAvalancheConfig.ReservesConfig[`${token}`].strategy.optimalUtilizationRate,
      stableRateSlope1: XaveAvalancheConfig.ReservesConfig[`${token}`].strategy.stableRateSlope1,
      stableRateSlope2: XaveAvalancheConfig.ReservesConfig[`${token}`].strategy.stableRateSlope2,
      tokenAddress: XaveAvalancheConfig.ReserveAssets[eAvalancheNetwork.avalanche][`${token}`],
      tokenReserve: token,
      variableRateSlope1: XaveAvalancheConfig.ReservesConfig[`${token}`].strategy.variableRateSlope1,
      variableRateSlope2: XaveAvalancheConfig.ReservesConfig[`${token}`].strategy.variableRateSlope2,
    });

    borrowRates.push(XaveAvalancheConfig.LendingRateOracleRatesCommon[`${token}`].borrowRate);
  }
  await getXaveDeploymentDb('avalanche').set('borrowRates', borrowRates).write();
  await getXaveDeploymentDb('avalanche').set(`marketId`, XaveAvalancheConfig.MarketId).write();
  await getXaveDeploymentDb('avalanche').set('rateStrategy', rateStrategy).write();
  await getXaveDeploymentDb('avalanche').set('reserveConfigs', reserveValue).write();
});
