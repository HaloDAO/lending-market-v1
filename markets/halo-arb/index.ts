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
    [eEthereumNetwork.kovan]: {},
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {},
    [eEthereumNetwork.tenderly]: {},
    [eArbitrumNetwork.arbitrum]: {
      // DAI: '',
      //TUSD: '0x0000000000085d4780B73119b644AE5ecd22b376',
      WETH: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
      USDC: '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8',
      USDT: '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9',
      // WBTC: '',
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
