import { eEthereumNetwork, IXaveSepoliaConfiguration } from '../../helpers/types';
import { CommonsConfig } from './commons';
import { strategyUSDC, strategyXSGD, strategyLP_XSGD_USDC } from './reservesConfigs';

// ----------------
// POOL--SPECIFIC PARAMS
// ----------------

export const XaveSepoliaConfig: IXaveSepoliaConfiguration = {
  ...CommonsConfig,
  MarketId: 'Xave Sepolia Market',
  ProviderId: 4,
  ReservesConfig: {
    USDC: strategyUSDC,
    XSGD: strategyXSGD,
    LP_XSGD_USDC: strategyLP_XSGD_USDC,
  },
  ReserveAssets: {
    [eEthereumNetwork.sepolia]: {
      USDC: '0xB9f4E777491bb848578B6FBa5c8A744A40d11128',
      XSGD: '0x29388a985C5904BFa13524f8c3Cb8bC10A02864C',
      LP_XSGD_USDC: '0xb842336B3143a7C76EFDbc3Eb5bFadCa04d4d2Fa',
    },
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.kovan]: {},
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.tenderly]: {},
  },
};

export default XaveSepoliaConfig;
