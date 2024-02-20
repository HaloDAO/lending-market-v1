// import BigNumber from 'bignumber.js';
// import { oneRay } from '../../helpers/constants';
import { eContractid, IReserveParams } from '../../helpers/types';
import { rateStrategyStableThree } from './rateStrategies';

export const strategyUSDC: IReserveParams = {
  strategy: rateStrategyStableThree,
  baseLTVAsCollateral: '8000',
  liquidationThreshold: '9000', // @todo VERIFY
  liquidationBonus: '10500', // 5% liquidation bonus
  borrowingEnabled: true,
  stableBorrowRateEnabled: false,
  reserveDecimals: '6',
  aTokenImpl: eContractid.AToken,
  reserveFactor: '1000',
};

export const strategyXSGD: IReserveParams = {
  strategy: rateStrategyStableThree,
  baseLTVAsCollateral: '8000',
  liquidationThreshold: '9000', // @todo VERIFY
  liquidationBonus: '10500', // 5% liquidation bonus
  borrowingEnabled: true,
  stableBorrowRateEnabled: false,
  reserveDecimals: '6',
  aTokenImpl: eContractid.AToken,
  reserveFactor: '1000',
};

//@todo add strategy for LPs
