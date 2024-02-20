import { eAvalancheNetwork, IXaveAvalancheConfiguration } from '../../helpers/types';

import { CommonsConfig } from './commons';
import { strategyUSDC, strategyXSGD } from './reservesConfigs';

// ----------------
// POOL--SPECIFIC PARAMS
// ----------------

export const XaveAvalancheConfig: IXaveAvalancheConfiguration = {
  ...CommonsConfig,
  MarketId: 'Xave Avalanche Market',
  ProviderId: 3, // @todo check
  ReservesConfig: {
    USDC: strategyUSDC,
    XSGD: strategyXSGD,
  },
  ReserveAssets: {
    [eAvalancheNetwork.avalanche]: {
      USDC: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
      XSGD: '0xDC3326e71D45186F113a2F448984CA0e8D201995',
    },
    [eAvalancheNetwork.fuji]: {
      USDC: '',
      XSGD: '',
    },
  },
};

export default XaveAvalancheConfig;
