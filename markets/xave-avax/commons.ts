import BigNumber from 'bignumber.js';
import { oneEther, oneRay, RAY, ZERO_ADDRESS, MOCK_CHAINLINK_AGGREGATORS_PRICES } from '../../helpers/constants';
import { ICommonConfiguration, eAvalancheNetwork } from '../../helpers/types';

// ----------------
// PROTOCOL GLOBAL PARAMS
// ----------------

export const CommonsConfig: ICommonConfiguration = {
  MarketId: 'Commons',
  ATokenNamePrefix: 'Xave Avalanche Market',
  StableDebtTokenNamePrefix: 'Xave Avalanche Market stable debt',
  VariableDebtTokenNamePrefix: 'Xave  Avalanche Market variable debt',
  SymbolPrefix: 'x',
  ProviderId: 0, // Overriden in index.ts
  OracleQuoteCurrency: 'ETH',
  OracleQuoteUnit: oneEther.toString(),
  ProtocolGlobalParams: {
    TokenDistributorPercentageBase: '10000',
    MockUsdPriceInWei: '5848466240000000',
    UsdAddress: '0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96',
    NilAddress: '0x0000000000000000000000000000000000000000',
    OneAddress: '0x0000000000000000000000000000000000000001',
    AaveReferral: '0',
  },

  // ----------------
  // COMMON PROTOCOL PARAMS ACROSS POOLS AND NETWORKS
  // ----------------

  Mocks: {
    AllAssetsInitialPrices: {
      ...MOCK_CHAINLINK_AGGREGATORS_PRICES,
    },
  },
  // TODO: reorg alphabetically, checking the reason of tests failing

  LendingRateOracleRatesCommon: {
    USDC: {
      borrowRate: oneRay.multipliedBy(0.039).toFixed(),
    },
    VCHF: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },
    EUROC: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },
    VEUR: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },
    LP_EUROC_USDC: { borrowRate: oneRay.multipliedBy(0).toFixed() },
    LP_VEUR_USDC: { borrowRate: oneRay.multipliedBy(0).toFixed() },
    LP_VCHF_USDC: { borrowRate: oneRay.multipliedBy(0).toFixed() },
  },
  // ----------------
  // COMMON PROTOCOL ADDRESSES ACROSS POOLS
  // ----------------

  // If PoolAdmin/emergencyAdmin is set, will take priority over PoolAdminIndex/emergencyAdminIndex
  PoolAdmin: {
    [eAvalancheNetwork.avalanche]: '0x009c4ba01488A15816093F96BA91210494E2C644',
    [eAvalancheNetwork.fuji]: '0x009c4ba01488A15816093F96BA91210494E2C644',
  },
  PoolAdminIndex: 0,
  EmergencyAdminIndex: 0,
  EmergencyAdmin: {
    [eAvalancheNetwork.avalanche]: '0x009c4ba01488A15816093F96BA91210494E2C644',
    [eAvalancheNetwork.fuji]: '0x009c4ba01488A15816093F96BA91210494E2C644',
  },
  ProviderRegistry: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  ProviderRegistryOwner: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  LendingRateOracle: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  LendingPoolCollateralManager: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  LendingPoolConfigurator: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  LendingPool: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  WethGateway: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: '0x62AF6258d26838f33BADFbb33cf1De8FaB8EB19f',
  },
  TokenDistributor: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  AaveOracle: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  FallbackOracle: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  ChainlinkAggregator: {
    [eAvalancheNetwork.avalanche]: {
      USDC: '0x29388a985C5904BFa13524f8c3Cb8bC10A02864C',
      VCHF: '0x132b37560040268aA7c03F6C4f415F0eBf30A87b',
      EUROC: '0xB9f4E777491bb848578B6FBa5c8A744A40d11128',
      VEUR: '0xA7F333136d5cB3E26f95247Be2CCea4731ab6eAa',
      LP_EUROC_USDC: '0x94d81606Dca42D3680c0DFc1d93eeaF6C2D55f2d',
      LP_VEUR_USDC: '0x6360a8Adb883CA076e7F2c6d2fF37531A771e414',
      LP_VCHF_USDC: '0xe5d80E9A857BF5cc73e40144cb28c8a401BdAe0c',
    },
    [eAvalancheNetwork.fuji]: {},
  },
  ReserveAssets: {
    [eAvalancheNetwork.avalanche]: {},
    [eAvalancheNetwork.fuji]: {},
  },
  ReservesConfig: {},
  ATokenDomainSeparator: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  WETH: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  WrappedNativeToken: {
    [eAvalancheNetwork.avalanche]: '0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7', // Official WAVAX
    [eAvalancheNetwork.fuji]: '0xd00ae08403B9bbb9124bB305C09058E32C39A48c', // Official WAVAX
  },
  ReserveFactorTreasuryAddress: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS, // Self-controlled EOA for testing
  },
  IncentivesController: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
};
