import BigNumber from 'bignumber.js';
import { oneEther, oneRay, RAY, ZERO_ADDRESS, MOCK_CHAINLINK_AGGREGATORS_PRICES_HALO } from '../../helpers/constants';
import { ICommonConfiguration, eEthereumNetwork } from '../../helpers/types';

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
      ...MOCK_CHAINLINK_AGGREGATORS_PRICES_HALO,
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
    TUSD: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },
    USDC: {
      borrowRate: oneRay.multipliedBy(0.039).toFixed(),
    },
    SUSD: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },
    USDT: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },
    RNBW: {
      borrowRate: oneRay.multipliedBy(0.03).toFixed(),
    },
    WBTC: {
      borrowRate: oneRay.multipliedBy(0.03).toFixed(),
    },
    BUSD: {
      borrowRate: oneRay.multipliedBy(0.05).toFixed(),
    },
    XSGD: {
      borrowRate: oneRay.multipliedBy(0.039).toFixed(),
    },
  },

  // ----------------
  // COMMON PROTOCOL ADDRESSES ACROSS POOLS
  // ----------------
  // If PoolAdmin/emergencyAdmin is set, will take priority over PoolAdminIndex/emergencyAdminIndex
  PoolAdmin: {
    [eEthereumNetwork.coverage]: undefined,
    [eEthereumNetwork.buidlerevm]: undefined,
    [eEthereumNetwork.coverage]: undefined,
    [eEthereumNetwork.hardhat]: undefined,
    [eEthereumNetwork.kovan]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    [eEthereumNetwork.ropsten]: undefined,
    [eEthereumNetwork.main]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    [eEthereumNetwork.tenderly]: undefined,
  },
  PoolAdminIndex: 0,
  EmergencyAdmin: {
    [eEthereumNetwork.hardhat]: undefined,
    [eEthereumNetwork.coverage]: undefined,
    [eEthereumNetwork.buidlerevm]: undefined,
    [eEthereumNetwork.kovan]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    [eEthereumNetwork.ropsten]: undefined,
    [eEthereumNetwork.main]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    [eEthereumNetwork.tenderly]: undefined,
  },
  EmergencyAdminIndex: 1,
  ProviderRegistry: {
    [eEthereumNetwork.kovan]: '0xD692fb541265a8FB4dF4528c775735e4F535907F',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  ProviderRegistryOwner: {
    [eEthereumNetwork.kovan]: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  LendingRateOracle: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0xFf4b5a92240CBaa0384f3d7f5e2D50772A80c42E',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  LendingPoolCollateralManager: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0x879ed8d0d2Fb84764D9aE9EF0fcE60B178593CE0',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  LendingPoolConfigurator: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0xBc61245fD99A65470A952e6661A9D630E7b47842',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  LendingPool: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0xcE1E8c1b7664ae8E71180D40e9c160D243f211e1',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  WethGateway: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0xfB56E8841C55DaA9A2A556BB8df24329E376a9A1',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  TokenDistributor: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.kovan]: '',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  AaveOracle: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0x28408A6fCb70268f3CD7a3af384942DD596fAe27',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  FallbackOracle: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  ChainlinkAggregator: {
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.kovan]: {
      BUSD: '0xbF7A18ea5DE0501f7559144e702b29c55b055CcB',
      DAI: '0x22B58f1EbEDfCA50feF632bD73368b2FdA96D541',
      TUSD: '0x7aeCF1c19661d12E962b69eBC8f6b2E63a55C660',
      USDC: '0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838',
      USDT: '0x0bF499444525a23E7Bb61997539725cA2e928138',
      USD: '0x9326BFA02ADD2366b30bacB125260Af641031331',
    },
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {
      BUSD: '0x614715d2Af89E6EC99A233818275142cE88d1Cfd',
      DAI: '0x773616E4d11A78F511299002da57A0a94577F1f4',
      SUSD: '0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757',
      TUSD: '0x3886BA987236181D98F2401c507Fb8BeA7871dF2',
      USDC: '0x986b5E1e1755e3C2440e960477f25201B0a8bbD4',
      USDT: '0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46',
      WBTC: '0xdeb288F737066589598e9214E782fa5A8eD689e8',
      USD: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', // TODO: Check
    },
    [eEthereumNetwork.tenderly]: {},
  },
  ReserveAssets: {
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.main]: {},
    [eEthereumNetwork.kovan]: {},
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.tenderly]: {},
  },
  ReservesConfig: {},
  ATokenDomainSeparator: {
    [eEthereumNetwork.coverage]: '0x95b73a72c6ecf4ccbbba5178800023260bad8e75cdccdb8e4827a2977a37c820',
    [eEthereumNetwork.hardhat]: '0xbae024d959c6a022dc5ed37294cd39c141034b2ae5f02a955cce75c930a81bf5',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  WETH: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0x6E7FC5B6E96B125D44eF93BFf86E21A5413C70Cf',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
    [eEthereumNetwork.tenderly]: '',
  },
  WrappedNativeToken: {
    [eEthereumNetwork.coverage]: '',
    [eEthereumNetwork.hardhat]: '',
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0x6E7FC5B6E96B125D44eF93BFf86E21A5413C70Cf',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  ReserveFactorTreasuryAddress: {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: '',
    [eEthereumNetwork.kovan]: '0xc6302b5062190513B79b10DE1DC3b232b1964131',
    [eEthereumNetwork.ropsten]: '',
    [eEthereumNetwork.main]: '',
    [eEthereumNetwork.tenderly]: '',
  },
  IncentivesController: {
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: '0x8Bfa7b45Ad86df7BeD67E91A676b7495B0402d04',
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  OracleQuoteCurrency: 'ETH',
  OracleQuoteUnit: oneEther.toString(),
};
