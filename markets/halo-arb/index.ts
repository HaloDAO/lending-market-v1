import { IHaloConfiguration, eEthereumNetwork, eArbitrumNetwork } from '../../helpers/types';

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
} from './reservesConfigs';

// ----------------
// POOL--SPECIFIC PARAMS
// ----------------

export const HaloArbConfig: IHaloConfiguration = {
  ...CommonsConfig,
  MarketId: 'HaloDAO Arb Lending Market',
  ProviderId: 1,
  ReservesConfig: {
    DAI: strategyDAI,
    USDC: strategyUSDC,
    USDT: strategyUSDT,
    WBTC: strategyWBTC,
    WETH: strategyWETH,
    XSGD: strategyXSGD,
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
    },
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {
      DAI: '0x6b175474e89094c44da98b954eedeac495271d0f',
      //TUSD: '0x0000000000085d4780B73119b644AE5ecd22b376',
      WETH: '0xDD03Fd22858ee6a3fa752c7872fC670Da52B58Da',
      USDC: '0xE2ea809d18B3AD1ac3839dFa01f8F4870D5ad917',
      USDT: '0xc1823C66137BF758d1Ac6d2675a62b256a89b143',
      WBTC: '0x42721E500325A725B29309116496adbBE1AE4a7e',
      // BUSD: '0x4fabb145d64652a948d72533023f6e7a623c7c53', // To Check
      // SUSD: '0x57ab1ec28d129707052df4df418d58a2d46d5f51', // To Check
    },
    [eEthereumNetwork.tenderly]: {},
    [eArbitrumNetwork.arbitrum]: {
      DAI: '',
      //TUSD: '0x0000000000085d4780B73119b644AE5ecd22b376',
      WETH: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
      USDC: '',
      USDT: '',
      WBTC: '',
      // BUSD: '0x4fabb145d64652a948d72533023f6e7a623c7c53', // To Check
      // SUSD: '0x57ab1ec28d129707052df4df418d58a2d46d5f51', // To Check
    },
    [eArbitrumNetwork.arbitrumRinkeby]: {
      DAI: '0xD9a078A31EFBc2ec72f3856a5FEc45A307895aFa',
      //TUSD: '0x0000000000085d4780B73119b644AE5ecd22b376',
      WETH: '0xDD03Fd22858ee6a3fa752c7872fC670Da52B58Da',
      USDC: '0xE2ea809d18B3AD1ac3839dFa01f8F4870D5ad917',
      USDT: '0xc1823C66137BF758d1Ac6d2675a62b256a89b143',
      // WBTC: '0x42721E500325A725B29309116496adbBE1AE4a7e',
      // BUSD: '0x4fabb145d64652a948d72533023f6e7a623c7c53', // To Check
      // SUSD: '0x57ab1ec28d129707052df4df418d58a2d46d5f51', // To Check
    },
  },
};

export default HaloArbConfig;
