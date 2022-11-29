import BigNumber from 'bignumber.js';
import { oneEther, oneRay, RAY, ZERO_ADDRESS, MOCK_CHAINLINK_AGGREGATORS_PRICES } from '../../helpers/constants';
import { ICommonConfiguration, ePolygonNetwork } from '../../helpers/types';
import { matic } from '@halodao/halodao-contract-addresses';

// ----------------
// PROTOCOL GLOBAL PARAMS
// ----------------

export const CommonsConfig: ICommonConfiguration = {
  MarketId: 'Commons',
  ATokenNamePrefix: 'Xave Matic Market',
  StableDebtTokenNamePrefix: 'Xave Matic Market stable debt',
  VariableDebtTokenNamePrefix: 'Xave Matic Market variable debt',
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
    WETH: {
      borrowRate: oneRay.multipliedBy(0.03).toFixed(),
    },
    DAI: {
      borrowRate: oneRay.multipliedBy(0.039).toFixed(),
    },
    USDC: {
      borrowRate: oneRay.multipliedBy(0.039).toFixed(),
    },
    USDT: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },
    WBTC: {
      borrowRate: oneRay.multipliedBy(0.03).toFixed(),
    },
    WMATIC: {
      borrowRate: oneRay.multipliedBy(0.05).toFixed(),
    },
    AAVE: {
      borrowRate: oneRay.multipliedBy(0.03).toFixed(),
    },
  },
  // ----------------
  // COMMON PROTOCOL ADDRESSES ACROSS POOLS
  // ----------------

  // If PoolAdmin/emergencyAdmin is set, will take priority over PoolAdminIndex/emergencyAdminIndex
  PoolAdmin: {
    [ePolygonNetwork.mumbai]: undefined,
    [ePolygonNetwork.matic]: undefined,
  },
  PoolAdminIndex: 0,
  EmergencyAdminIndex: 0,
  EmergencyAdmin: {
    [ePolygonNetwork.mumbai]: undefined,
    [ePolygonNetwork.matic]: undefined,
  },
  LendingPool: {
    [ePolygonNetwork.mumbai]: '',
    [ePolygonNetwork.matic]: '0x78a5B2B028Fa6Fb0862b0961EB5131C95273763B',
  },
  LendingPoolConfigurator: {
    [ePolygonNetwork.mumbai]: '',
    [ePolygonNetwork.matic]: '0x0228bda708F5BA3b188D9CC8588B7dA4E254D492',
  },
  ProviderRegistry: {
    [ePolygonNetwork.mumbai]: '0xE6ef11C967898F9525D550014FDEdCFAB63536B5',
    [ePolygonNetwork.matic]: '0xd25792c918b38dEE6e7A96cB609718ce5F3E249c',
  },
  ProviderRegistryOwner: {
    [ePolygonNetwork.mumbai]: '0x943E44157dC0302a5CEb172374d1749018a00994',
    [ePolygonNetwork.matic]: '0x01e198818a895f01562e0a087595e5b1c7bb8d5c',
  },
  LendingRateOracle: {
    [ePolygonNetwork.mumbai]: '0xC661e1445F9a8E5FD3C3dbCa0A0A2e8CBc79725D',
    [ePolygonNetwork.matic]: '0x25290edB1633c6b60a24C5FB3a321b91a67Cafe7',
  },
  LendingPoolCollateralManager: {
    [ePolygonNetwork.mumbai]: '0x2A7004B21c49253ca8DF923406Fed9a02AA86Ba0',
    [ePolygonNetwork.matic]: '0xDF512Eb2468D4938D81fA1F15d91567c5EdEe6a8',
  },
  TokenDistributor: {
    [ePolygonNetwork.mumbai]: '',
    [ePolygonNetwork.matic]: '',
  },
  WethGateway: {
    [ePolygonNetwork.mumbai]: '',
    [ePolygonNetwork.matic]: '0x2Ef9AB2ce7Bd97b1e893583ba91aCA6A883dF0F2',
  },
  AaveOracle: {
    [ePolygonNetwork.mumbai]: '',
    [ePolygonNetwork.matic]: '0x0200889C2733bB78641126DF27A0103230452b62',
  },
  FallbackOracle: {
    [ePolygonNetwork.mumbai]: ZERO_ADDRESS,
    [ePolygonNetwork.matic]: ZERO_ADDRESS,
  },
  ChainlinkAggregator: {
    [ePolygonNetwork.matic]: {
      AAVE: '0xbE23a3AA13038CfC28aFd0ECe4FdE379fE7fBfc4',
      DAI: '0xFC539A559e170f848323e19dfD66007520510085',
      USDC: '0xefb7e6be8356cCc6827799B6A7348eE674A80EaE',
      USDT: '0xf9d5AAC6E5572AEFa6bd64108ff86a222F69B64d',
      WBTC: '0xA338e0492B2F944E9F8C0653D3AD1484f2657a37',
      WMATIC: '0x327e23A4855b6F663a28c5161541d69Af8973302',
      USD: '0xF9680D99D6C9589e2a93a78A04A279e509205945',
      FXPHP: '0x24eA470A0836B5D24d82fEf1f55ad4C79DFd0b04',
      TAGPHP: '0x24eA470A0836B5D24d82fEf1f55ad4C79DFd0b04',
      XSGD: '0x22070511b8985C8694413847ed81E6A856d27D33',
      BPT_XSGD_USDC: '0xbca5c841eC9cC6Bd54ee18450eAe3B4D7b68146b',
    },
    [ePolygonNetwork.mumbai]: {
      DAI: ZERO_ADDRESS,
      USDC: ZERO_ADDRESS,
      USDT: ZERO_ADDRESS,
      WBTC: ZERO_ADDRESS,
      WMATIC: ZERO_ADDRESS,
      USD: ZERO_ADDRESS,
    },
  },
  ReserveAssets: {
    [ePolygonNetwork.matic]: {},
    [ePolygonNetwork.mumbai]: {},
  },
  ReservesConfig: {},
  ATokenDomainSeparator: {
    [ePolygonNetwork.mumbai]: '',
    [ePolygonNetwork.matic]: '',
  },
  WETH: {
    [ePolygonNetwork.mumbai]: ZERO_ADDRESS,
    [ePolygonNetwork.matic]: '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
  },
  WrappedNativeToken: {
    [ePolygonNetwork.mumbai]: '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889',
    [ePolygonNetwork.matic]: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
  },
  ReserveFactorTreasuryAddress: {
    [ePolygonNetwork.mumbai]: ZERO_ADDRESS,
    [ePolygonNetwork.matic]: '0x5560659d9a4aB330dE2112fc8Ee0989857197728',
  },
  IncentivesController: {
    [ePolygonNetwork.mumbai]: '0xd41aE58e803Edf4304334acCE4DC4Ec34a63C644',
    [ePolygonNetwork.matic]: '0x19EEF75223F5E191D1022a11dAf7f9c29e9473f3',
  },
};
