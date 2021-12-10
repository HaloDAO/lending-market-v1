import { oneRay, ZERO_ADDRESS } from '../../helpers/constants';
import { IHaloConfiguration, eEthereumNetwork } from '../../helpers/types';

import { CommonsConfig } from './commons';
import {
  strategyBUSD,
  strategyDAI,
  strategySUSD,
  strategyTUSD,
  strategyUSDC,
  strategyXSGD,
  strategyTHKD,
  strategyUSDT,
  strategyAAVE,
  strategyWBTC,
  strategyWETH,
} from './reservesConfigs';

// ----------------
// POOL--SPECIFIC PARAMS
// ----------------

export const HaloConfig: IHaloConfiguration = {
  ...CommonsConfig,
  MarketId: 'Halo genesis market',
  ProviderId: 1,
  ReservesConfig: {
    //AAVE: strategyAAVE,
    RNBW: strategyAAVE,
    BUSD: strategyBUSD,
    DAI: strategyDAI,
    XSGD: strategyXSGD,
    THKD: strategyTHKD,
    SUSD: strategySUSD,
    TUSD: strategyTUSD,
    USDC: strategyUSDC,
    USDT: strategyUSDT,
    WBTC: strategyWBTC,
    WETH: strategyWETH,
  },
  ReserveAssets: {
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.kovan]: {
      DAI: '0x33988C7f1333773DCCE4c5d28cc4e785a7a07711',
      AAVE: '0x0BBf903848a9cf033371B006D4b5D7E7A2EE028F',
      TUSD: '0x0B17056eeCf85b9706421ACa9048188DE082094e',
      WETH: '0x6E7FC5B6E96B125D44eF93BFf86E21A5413C70Cf',
      USDC: '0x4B466AeAa9c5f639fE7eA5A4692e9ca34afD9CC6',
      USDT: '0x98388b94c7bEF52CD361fcf037c7249BB6D4282b',
      SUSD: '0xC8d1AeC01DB97EdFd66a5B91136EC34068fE917a',
      WBTC: '0xeD57b6849762Ead86f71b41eEC743cE261639Aa8',
      BUSD: '0x75A3207832889d35776479F932417aB340C7caEe',
    },
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {},
    [eEthereumNetwork.tenderlyMain]: {},
  },
};

export default HaloConfig;
