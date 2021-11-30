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

/*


      
*/
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
      RNBW: '0x134C899E4794F02Bbaf4a3CC68E6032d8f12B41C',
      XSGD: '0x51Ca80516644928dbf8c5af5853Dc01bfe8A8f43',
      USDC: '0x12513dd17Ae75AF37d9eb21124f98b04705Be906',
    },
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {},
    [eEthereumNetwork.tenderlyMain]: {},
  },
};

export default HaloConfig;
