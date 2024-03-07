import { ConfigNames, loadPoolConfig } from './configuration';
import { ZERO_ADDRESS } from './constants';
import { getXaveDeploymentDb } from './misc-utils';
import { eArbitrumNetwork, eAvalancheNetwork, eEthereumNetwork, ePolygonNetwork } from './types';

import {
  mainnet,
  kovan,
  rinkeby,
  matic,
  arb,
  avalanche,
  arbTestnet,
  goerli,
  apothem,
  sepolia,
} from '@halodao/halodao-contract-addresses';

type ReserveValue = {
  aTokenImpl: string;
  baseLTVAsCollateral: string;
  borrowingEnabled: string;
  liquidationBonus: string;
  liquidationThreshold: string;
  reserveDecimals: string;
  reserveFactor: string;
  stableBorrowRateEnabled: string;
  tokenReserve: string;
};

type RateStrategy = {
  baseVariableBorrowRate: string;
  name: string;
  optimalUtilizationRate: string;
  stableRateSlope1: string;
  stableRateSlope2: string;
  tokenReserve: string;
  variableRateSlope1: string;
  variableRateSlope2: string;
};

type ChainLinkAggregator = {
  aggregator: string;
  tokenReserve: string;
};

type Tokens = {
  addr: string;
  borrowRate: string;
  chainLinkAggregator: ChainLinkAggregator;
  rateStrategy: RateStrategy;
  reserveConfig: ReserveValue;
};

const getHaloAddresses = (network: string) => {
  switch (network) {
    case 'kovan':
      return kovan;
    case 'rinkeby':
      return rinkeby;
    case 'arbTestnet':
      return arbTestnet;
    case 'mainnet':
      return mainnet;
    case 'matic':
      return matic;
    case 'arb':
      return arb;
    case 'goerli':
      return goerli;
    case 'apothem':
      return apothem;
    case 'avalanche':
      return avalanche;
    case 'sepolia':
      return sepolia;
    default:
      return undefined;
  }
};

export const getOpsMultisig = (network: string) => {
  const haloAddresses = getHaloAddresses(network);
  if (!haloAddresses) return undefined;
  return haloAddresses.ops.multisig;
};

// USDETH, Native Token - ETH
const ethAndNativeAggregators: {
  [key: string]: { ethUsdOracle: string; nativeTokenOracle: string };
} = {
  [eEthereumNetwork.kovan]: {
    ethUsdOracle: '0x9326BFA02ADD2366b30bacB125260Af641031331',
    nativeTokenOracle: '0x9326BFA02ADD2366b30bacB125260Af641031331',
  },
  [eEthereumNetwork.sepolia]: {
    ethUsdOracle: '0x694AA1769357215DE4FAC081bf1f309aDC325306',
    nativeTokenOracle: '0x694AA1769357215DE4FAC081bf1f309aDC325306',
  },
  [eEthereumNetwork.main]: {
    ethUsdOracle: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419',
    nativeTokenOracle: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419',
  },
  [ePolygonNetwork.matic]: {
    ethUsdOracle: '0xf9680d99d6c9589e2a93a78a04a279e509205945',
    nativeTokenOracle: '0x327e23A4855b6F663a28c5161541d69Af8973302',
  },
  //@todo: replace with actual ETH/USD oracle for Arbitrum network
  [eArbitrumNetwork.arbitrumRinkeby]: {
    ethUsdOracle: '0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8',
    nativeTokenOracle: '0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8',
  },
  [eArbitrumNetwork.arbitrum]: {
    ethUsdOracle: '0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612',
    nativeTokenOracle: '0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612',
  },
  [eAvalancheNetwork.avalanche]: {
    ethUsdOracle: '0x976B3D034E162d8bD72D6b9C989d545b839003b0',
    nativeTokenOracle: ZERO_ADDRESS,
  },
  [eAvalancheNetwork.fuji]: {
    ethUsdOracle: '0x86d67c3D38D2bCeE722E601025C25a575021c6EA',
    nativeTokenOracle: ZERO_ADDRESS,
  },
};

export const generateMarketConfigJSON = async (
  tokens: string[],
  config: ConfigNames,
  network: eEthereumNetwork | ePolygonNetwork | eArbitrumNetwork | eAvalancheNetwork
) => {
  const poolConfig = loadPoolConfig(config);
  let tokenList: Tokens[] = [];

  for (var token of tokens) {
    console.log(`Writing for ${token}`);

    tokenList.push({
      addr: poolConfig.ReserveAssets[network][`${token}`],
      borrowRate: poolConfig.LendingRateOracleRatesCommon[`${token}`].borrowRate,
      chainLinkAggregator: {
        aggregator: poolConfig.ChainlinkAggregator[network][`${token}`],
        tokenReserve: token,
      },
      rateStrategy: {
        baseVariableBorrowRate: poolConfig.ReservesConfig[`${token}`].strategy.baseVariableBorrowRate,
        name: poolConfig.ReservesConfig[`${token}`].strategy.name,
        optimalUtilizationRate: poolConfig.ReservesConfig[`${token}`].strategy.optimalUtilizationRate,
        stableRateSlope1: poolConfig.ReservesConfig[`${token}`].strategy.stableRateSlope1,
        stableRateSlope2: poolConfig.ReservesConfig[`${token}`].strategy.stableRateSlope2,
        tokenReserve: token,
        variableRateSlope1: poolConfig.ReservesConfig[`${token}`].strategy.variableRateSlope1,
        variableRateSlope2: poolConfig.ReservesConfig[`${token}`].strategy.variableRateSlope2,
      },
      reserveConfig: {
        aTokenImpl: poolConfig.ReservesConfig[`${token}`].aTokenImpl,
        baseLTVAsCollateral: poolConfig.ReservesConfig[`${token}`].baseLTVAsCollateral,
        borrowingEnabled: poolConfig.ReservesConfig[`${token}`].borrowingEnabled,
        liquidationBonus: poolConfig.ReservesConfig[`${token}`].liquidationBonus,
        liquidationThreshold: poolConfig.ReservesConfig[`${token}`].liquidationThreshold,
        reserveDecimals: poolConfig.ReservesConfig[`${token}`].reserveDecimals,
        reserveFactor: poolConfig.ReservesConfig[`${token}`].reserveFactor,
        stableBorrowRateEnabled: poolConfig.ReservesConfig[`${token}`].stableBorrowRateEnabled,
        tokenReserve: token,
      },
    });
  }

  await getXaveDeploymentDb(network)
    .set('deploymentParams', {
      poolAdmin: poolConfig.PoolAdmin[network],
      poolEmergencyAdmin: poolConfig.EmergencyAdmin[network],
    })
    .write();

  await getXaveDeploymentDb(network)
    .set('protocolGlobalParams', {
      ethUsdAggregator: ethAndNativeAggregators[network].ethUsdOracle,
      marketId: poolConfig.MarketId,
      nativeTokenUsdAggregator: ethAndNativeAggregators[network].ethUsdOracle, // keeping this as this gives the most accurate info
      treasury: getOpsMultisig(eEthereumNetwork.sepolia),
      usdAddress: poolConfig.ProtocolGlobalParams.UsdAddress,
      wethAddress: poolConfig.WETH[network],
    })
    .write();

  await getXaveDeploymentDb(network).set('tokens', tokenList).write();
};
