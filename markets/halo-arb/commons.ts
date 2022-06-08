import BigNumber from 'bignumber.js';
import {
  oneEther,
  oneRay,
  RAY,
  ZERO_ADDRESS,
  MOCK_CHAINLINK_AGGREGATORS_PRICES_HALO,
  MOCK_CHAINLINK_AGGREGATORS_PRICES,
} from '../../helpers/constants';
import { ICommonConfiguration, eArbitrumNetwork } from '../../helpers/types';

// ----------------
// PROTOCOL GLOBAL PARAMS
// ----------------

export const CommonsConfig: ICommonConfiguration = {
  MarketId: 'Commons',
  ATokenNamePrefix: 'Halo interest bearing',
  StableDebtTokenNamePrefix: 'Halo stable debt bearing',
  VariableDebtTokenNamePrefix: 'Halo variable debt bearing',
  SymbolPrefix: 'h',
  ProviderId: 0,
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
    //TUSD: {
    //  borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    //},
    USDC: {
      borrowRate: oneRay.multipliedBy(0.039).toFixed(),
    },
    //SUSD: {
    //  borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    //},
    USDT: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },
    //RNBW: {
    //  borrowRate: oneRay.multipliedBy(0.03).toFixed(),
    //},
    WBTC: {
      borrowRate: oneRay.multipliedBy(0.03).toFixed(),
    },
    // BUSD: {
    //   borrowRate: oneRay.multipliedBy(0.05).toFixed(),
    // },
    // XSGD: {
    //   borrowRate: oneRay.multipliedBy(0.039).toFixed(),
    // },
  },

  // ----------------
  // COMMON PROTOCOL ADDRESSES ACROSS POOLS
  // ----------------
  // If PoolAdmin/emergencyAdmin is set, will take priority over PoolAdminIndex/emergencyAdminIndex
  PoolAdmin: {
    [eArbitrumNetwork.arbitrum]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
  },
  PoolAdminIndex: 0,
  EmergencyAdmin: {
    [eArbitrumNetwork.arbitrum]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
  },
  EmergencyAdminIndex: 1,
  ProviderRegistry: {
    [eArbitrumNetwork.arbitrum]: '0x25623Ae6CfaaF1cEac5d31c5e591Dd9920281a11',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x91dE07ec42431266F7a501cE09abaaf0ca9B4161',
  },
  ProviderRegistryOwner: {
    [eArbitrumNetwork.arbitrum]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
  },
  LendingRateOracle: {
    [eArbitrumNetwork.arbitrum]: '0xF8Ab9b85bdf19A707De091290aFBEa09b0c5D1f9',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x796aF82AbaB46D68FFA66c5B56b953A1ABFda101',
  },
  LendingPoolCollateralManager: {
    [eArbitrumNetwork.arbitrum]: '0x6601A3610c6262b14336E18198922d0b4b9624A3',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
  },
  LendingPoolConfigurator: {
    [eArbitrumNetwork.arbitrum]: '0xC2402DBc9a6d90607f35E9ccf673aD08dB3cAF2B',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x7Ef194E7ff672ABD3246A8dD196385026b1Fb669',
  },
  LendingPool: {
    [eArbitrumNetwork.arbitrum]: '0xF9D8493b5220797b6ba572ea34D4f1d3a852e879',
    [eArbitrumNetwork.arbitrumRinkeby]: '0xDEE8ae2C14Be3bEab9ee194092c78C002697ab1C',
  },
  WethGateway: {
    [eArbitrumNetwork.arbitrum]: '0x25472d7b299692F13EbF872EcF0Fe2BaBCbcB4cD',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x47aEd020cDCAc6A1108C7EFbD0C5D51C20D3D8Aa',
  },
  TokenDistributor: {
    [eArbitrumNetwork.arbitrum]: '',
    [eArbitrumNetwork.arbitrumRinkeby]: '',
  },
  AaveOracle: {
    [eArbitrumNetwork.arbitrum]: '0x3f178B0E885688645f219852Caa014f5c7027703',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x6Dfc00598a5cad64af4B28805856b3e39eCAe47E',
  },
  FallbackOracle: {
    [eArbitrumNetwork.arbitrum]: '0x0000000000000000000000000000000000000000',
    [eArbitrumNetwork.arbitrumRinkeby]: '0x6Dfc00598a5cad64af4B28805856b3e39eCAe47E',
  },
  ChainlinkAggregator: {
    [eArbitrumNetwork.arbitrumRinkeby]: {
      //@todo: replace with actual ETH price oracle address for Arbitrum
      // BUSD: '0xbF7A18ea5DE0501f7559144e702b29c55b055CcB',
      DAI: '0x6eFd3CCf5c673bd5A7Ea91b414d0307a5bAb9cC1',
      //TUSD: '0x7aeCF1c19661d12E962b69eBC8f6b2E63a55C660',
      USDC: '0x6eFd3CCf5c673bd5A7Ea91b414d0307a5bAb9cC1',
      USDT: '0x6eFd3CCf5c673bd5A7Ea91b414d0307a5bAb9cC1',
      USD: '0x6eFd3CCf5c673bd5A7Ea91b414d0307a5bAb9cC1',
      WBTC: '0x6eFd3CCf5c673bd5A7Ea91b414d0307a5bAb9cC1',
    },
    [eArbitrumNetwork.arbitrum]: {
      //BUSD: '0x614715d2Af89E6EC99A233818275142cE88d1Cfd',
      // DAI: '',
      //SUSD: '0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757',
      //TUSD: '0x3886BA987236181D98F2401c507Fb8BeA7871dF2',
      USDC: '0x8AFAf5d086B5d97fC5045Bce452Ee1FA9adCC93e',
      USDT: '0x813abe589753c7dA64cC4EBEC638F6BeC530C12e',
      // WBTC: '',
      USD: '0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612',
      // WETH: '',
    },
  },
  ReserveAssets: {
    [eArbitrumNetwork.arbitrum]: {},
    [eArbitrumNetwork.arbitrumRinkeby]: {},
  },
  ReservesConfig: {},
  ATokenDomainSeparator: {
    [eArbitrumNetwork.arbitrum]: '0x95b73a72c6ecf4ccbbba5178800023260bad8e75cdccdb8e4827a2977a37c820',
    [eArbitrumNetwork.arbitrumRinkeby]: '0xbae024d959c6a022dc5ed37294cd39c141034b2ae5f02a955cce75c930a81bf5',
  },
  WETH: {
    [eArbitrumNetwork.arbitrum]: '0x82af49447d8a07e3bd95bd0d56f35241523fbab1',
    [eArbitrumNetwork.arbitrumRinkeby]: '',
  },
  WrappedNativeToken: {
    [eArbitrumNetwork.arbitrum]: '0x82af49447d8a07e3bd95bd0d56f35241523fbab1',
    [eArbitrumNetwork.arbitrumRinkeby]: '',
  },
  ReserveFactorTreasuryAddress: {
    [eArbitrumNetwork.arbitrum]: '0x19C96DbFfdFC2F6D5C30deF63F7D52234E516202', //multisig wallet address
    [eArbitrumNetwork.arbitrumRinkeby]: '',
  },
  IncentivesController: {
    [eArbitrumNetwork.arbitrum]: '0xA036734Aee3B5D906A25d6A2455E9CB0B7F9Df10',
    [eArbitrumNetwork.arbitrumRinkeby]: '',
  },
  OracleQuoteCurrency: 'ETH',
  OracleQuoteUnit: oneEther.toString(),
};
