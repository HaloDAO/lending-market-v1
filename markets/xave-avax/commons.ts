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
    UsdAddress: '0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96', // @todo check
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
  // @todo for the lp token
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
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  ProviderRegistryOwner: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  LendingRateOracle: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  LendingPoolCollateralManager: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  LendingPoolConfigurator: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  LendingPool: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  WethGateway: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '0x62AF6258d26838f33BADFbb33cf1De8FaB8EB19f',
  },
  TokenDistributor: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  AaveOracle: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  FallbackOracle: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
  ChainlinkAggregator: {
    [eAvalancheNetwork.avalanche]: {
      USDC: '0xF096872672F44d6EBA71458D74fe67F9a77a23B9', //@todo check others
    },
    [eAvalancheNetwork.fuji]: {},
  },
  ReserveAssets: {
    [eAvalancheNetwork.avalanche]: {},
    [eAvalancheNetwork.fuji]: {},
  },
  ReservesConfig: {},
  ATokenDomainSeparator: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  WETH: {
    [eAvalancheNetwork.avalanche]: '',
    [eAvalancheNetwork.fuji]: '',
  },
  WrappedNativeToken: {
    [eAvalancheNetwork.avalanche]: '0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7', // Official WAVAX
    [eAvalancheNetwork.fuji]: '0xd00ae08403B9bbb9124bB305C09058E32C39A48c', // Official WAVAX
  },
  ReserveFactorTreasuryAddress: {
    [eAvalancheNetwork.avalanche]: '', // @todo
    [eAvalancheNetwork.fuji]: '', // Self-controlled EOA for testing
  },
  IncentivesController: {
    [eAvalancheNetwork.avalanche]: ZERO_ADDRESS,
    [eAvalancheNetwork.fuji]: ZERO_ADDRESS,
  },
};
