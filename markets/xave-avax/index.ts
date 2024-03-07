import { eAvalancheNetwork, IXaveAvalancheConfiguration } from '../../helpers/types';

import { CommonsConfig } from './commons';
import {
  strategyEUROC,
  strategyLP_EUROC_USDC,
  strategyLP_VCHF_USDC,
  strategyLP_VEUR_USDC,
  strategyUSDC,
  strategyVCHF,
  strategyVEUR,
  strategyXSGD,
} from './reservesConfigs';

// ----------------
// POOL--SPECIFIC PARAMS
// ----------------

export const XaveAvalancheConfig: IXaveAvalancheConfiguration = {
  ...CommonsConfig,
  MarketId: 'Xave Avalanche Market',
  ProviderId: 3,
  ReservesConfig: {
    USDC: strategyUSDC,
    // XSGD: strategyXSGD,
    EUROC: strategyEUROC,
    VCHF: strategyVCHF,
    VEUR: strategyVEUR,
    LP_EUROC_USDC: strategyLP_EUROC_USDC,
    LP_VEUR_USDC: strategyLP_VEUR_USDC,
    LP_VCHF_USDC: strategyLP_VCHF_USDC,
  },
  ReserveAssets: {
    [eAvalancheNetwork.avalanche]: {
      USDC: '0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E',
      // XSGD: '0xDC3326e71D45186F113a2F448984CA0e8D201995',
      EUROC: '0xC891EB4cbdEFf6e073e859e987815Ed1505c2ACD',
      VCHF: '0x228a48df6819CCc2eCa01e2192ebAFfFdAD56c19',
      VEUR: '0x7678e162f38ec9ef2Bfd1d0aAF9fd93355E5Fa0b',
      LP_EUROC_USDC: '0x7A1A919c033eBc0d9F23cBF2Aa41c24AEf826ca2',
      LP_VEUR_USDC: '0x28F3a9e42667519c83cB090b5c4f6bd34e9F5569',
      LP_VCHF_USDC: '0x0099111Ed107BDF0B05162356aEe433514AaC440',
    },
    [eAvalancheNetwork.fuji]: {
      USDC: '',
      XSGD: '',
    },
  },
};

export default XaveAvalancheConfig;
