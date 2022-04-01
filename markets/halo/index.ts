import { IHaloConfiguration, eEthereumNetwork } from '../../helpers/types';
import { mainnet, kovan } from '@halodao/halodao-contract-addresses'

import { CommonsConfig } from './commons';
import {
  strategyBUSD,
  strategyDAI,
  strategySUSD,
  strategyTUSD,
  strategyUSDC,
  strategyUSDT,
  strategyWBTC,
  strategyWETH,
  strategyXSGD,
  strategyfxPHP,
  strategyCHF,
  strategyHLP_PHP_USDC,
  strategyHLP_XSGD_USDC,
} from './reservesConfigs';

// ----------------
// POOL--SPECIFIC PARAMS
// ----------------

export const HaloConfig: IHaloConfiguration = {
  ...CommonsConfig,
  MarketId: 'HaloDAO Lending Market',
  ProviderId: 1,
  ReservesConfig: {
    DAI: strategyDAI,
    USDC: strategyUSDC,
    USDT: strategyUSDT,
    WBTC: strategyWBTC,
    WETH: strategyWETH,
    XSGD: strategyXSGD,
    fxPHP: strategyfxPHP,
    CHF: strategyCHF,
    HLP_PHP_USDC: strategyHLP_PHP_USDC,
    HLP_XSGD_USDC: strategyHLP_XSGD_USDC
  },
  ReserveAssets: {
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.kovan]: {
      DAI: '0x33988C7f1333773DCCE4c5d28cc4e785a7a07711',
      WETH: '0x1363b62C9A82007e409876A71B524bD63dDc67Dd',
      USDC: '0x4B466AeAa9c5f639fE7eA5A4692e9ca34afD9CC6',
      USDT: '0x98388b94c7bEF52CD361fcf037c7249BB6D4282b',
      WBTC: '0xeD57b6849762Ead86f71b41eEC743cE261639Aa8',
      XSGD: kovan.tokens.XSGD!,
      fxPHP: kovan.tokens.fxPHP!,
      HLP_PHP_USDC: '0xEb06cF1cD90d75eC6d10bbdc43B555483674F6ff',
      CHF: kovan.tokens.CHF!
    },
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {
      DAI: '0x6b175474e89094c44da98b954eedeac495271d0f',
      //TUSD: '0x0000000000085d4780B73119b644AE5ecd22b376',
      WETH: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
      USDC: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
      USDT: '0xdac17f958d2ee523a2206206994597c13d831ec7',
      WBTC: '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599',
      XSGD: mainnet.tokens.XSGD!,
      fxPHP: mainnet.tokens.fxPHP!,
      HLP_PHP_USDC: '0x0000000000000000000000000000000000000000',
      HLP_XSGD_USDC: '0x64DCbDeb83e39f152B7Faf83E5E5673faCA0D42A',
      // BUSD: '0x4fabb145d64652a948d72533023f6e7a623c7c53', // To Check
      // SUSD: '0x57ab1ec28d129707052df4df418d58a2d46d5f51', // To Check
    },
    [eEthereumNetwork.tenderly]: {},
  },
};

export default HaloConfig;
