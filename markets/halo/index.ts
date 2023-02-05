import { kovan, mainnet } from '@halodao/halodao-contract-addresses';
import { IHaloConfiguration, eEthereumNetwork } from '../../helpers/types';

import { CommonsConfig } from './commons';
import {
  strategyBUSD,
  strategyDAI,
  strategyFXPHP,
  strategyHLPPHP,
  strategyHLP_UST_USDC,
  strategyHLP_XSGD_USDC,
  strategySUSD,
  strategyTUSD,
  strategyUSDC,
  strategyUSDT,
  strategyUST,
  strategyWBTC,
  strategyWETH,
  strategyXSGD,
  strategyMockUSDC,
  strategyLP_XSGD_USDC,
  strategyLP_FXPHP_USDC,
  strategyLP_EURS_USDC,
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
    RNBW: strategyWETH,
    XSGD: strategyXSGD,
    FXPHP: strategyFXPHP,
    UST: strategyUST,
    HLP_XSGD_USDC: strategyHLP_XSGD_USDC,
    HLP_UST_USDC: strategyHLP_UST_USDC,
    MockUSDC: strategyMockUSDC,
    LP_FXPHP_USDC: strategyLP_FXPHP_USDC,
    LP_EURS_USDC: strategyLP_EURS_USDC,
  },
  ReserveAssets: {
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.hardhat]: {
      DAI: '0x6b175474e89094c44da98b954eedeac495271d0f',
      //TUSD: '0x0000000000085d4780B73119b644AE5ecd22b376',
      WETH: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
      USDC: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
      USDT: '0xdac17f958d2ee523a2206206994597c13d831ec7',
      WBTC: '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599',
      XSGD: mainnet.tokens.XSGD!,
      FXPHP: mainnet.tokens.fxPHP!,
      UST: '0xa693b19d2931d498c5b318df961919bb4aee87a5',
      HLP_XSGD_USDC: '0x64DCbDeb83e39f152B7Faf83E5E5673faCA0D42A',
      HLP_UST_USDC: '0x868084406449bda10a5bd556fb33cef5086b0797',
    }, // WARNING: for mainnet fork, comment out if doing a fresh deploy in hardhat
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.kovan]: {
      DAI: '0x33988C7f1333773DCCE4c5d28cc4e785a7a07711',
      WETH: '0x1363b62C9A82007e409876A71B524bD63dDc67Dd',
      USDC: '0x4B466AeAa9c5f639fE7eA5A4692e9ca34afD9CC6',
      USDT: '0x98388b94c7bEF52CD361fcf037c7249BB6D4282b',
      WBTC: '0xeD57b6849762Ead86f71b41eEC743cE261639Aa8',
      XSGD: kovan.tokens.XSGD!,
      FXPHP: kovan.tokens.fxPHP!,
      HLPPHP: '0xEb06cF1cD90d75eC6d10bbdc43B555483674F6ff',
      HLP_XSGD_USDC: kovan.lendingMarket!.lpAssets.HLP_XSGD_USDC!,
      MockUSDC: kovan.tokens.USDC!,
      LP_XSGD_USDC: kovan.lendingMarket!.lpAssets.LP_XSGD_USDC!,
      LP_FXPHP_USDC: kovan.lendingMarket!.lpAssets.LP_FXPHP_USDC!,
    },
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {
      DAI: '0x6b175474e89094c44da98b954eedeac495271d0f',
      WETH: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
      USDC: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
      USDT: '0xdac17f958d2ee523a2206206994597c13d831ec7',
      WBTC: '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599',
      XSGD: mainnet.tokens.XSGD!,
      FXPHP: mainnet.tokens.fxPHP!,
      UST: mainnet.tokens.UST!,
      HLP_XSGD_USDC: '0x64DCbDeb83e39f152B7Faf83E5E5673faCA0D42A',
      HLP_UST_USDC: '0x868084406449bda10a5bd556fb33cef5086b0797',
      LP_EURS_USDC: mainnet.ammV2.pools.all.LP_EURS_USDC!,
    },
    [eEthereumNetwork.tenderly]: {},
    [eEthereumNetwork.goerli]: {
      DAI: '0xEF8143f052d225162C2660a0C7954ea3c6CAbb65',
      WETH: '0x87fb8C797709176f890A7FBDe6185B66cabC5B93',
      USDC: '0x6edE2292C4e9d3151169525af68D300f0C4EDbe1',
      USDT: '0xCEF6014D0834d922F99264aF64C5A51eFbE9735f',
      WBTC: '0x175ef0f7accf7cb3DEC16185e320873fe3cc56Aa',
      LP_XSGD_USDC: '0x5886F7BFCC5D61CD4Ad0DC34e72DEFa2c85dE104',
      LP_FXPHP_USDC: '0x1fbA91Ce46d2453e2d461b1a0FcF76588a07fE41',
    },
  },
};

export default HaloConfig;
