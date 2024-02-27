import { oneEther, oneRay, RAY, ZERO_ADDRESS, MOCK_CHAINLINK_AGGREGATORS_PRICES } from '../../helpers/constants';
import { ICommonConfiguration, eEthereumNetwork } from '../../helpers/types';

// ----------------
// PROTOCOL GLOBAL PARAMS
// ----------------

export const CommonsConfig: ICommonConfiguration = {
  MarketId: 'Commons',
  ATokenNamePrefix: 'Xave Sepolia Market',
  StableDebtTokenNamePrefix: 'Xave Sepolia Market stable debt',
  VariableDebtTokenNamePrefix: 'Xave  Sepolia Market variable debt',
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
    XSGD: {
      borrowRate: oneRay.multipliedBy(0.035).toFixed(),
    },

    LP_XSGD_USDC: { borrowRate: oneRay.multipliedBy(0).toFixed() },
  },
  // ----------------
  // COMMON PROTOCOL ADDRESSES ACROSS POOLS
  // ----------------

  // If PoolAdmin/emergencyAdmin is set, will take priority over PoolAdminIndex/emergencyAdminIndex
  PoolAdmin: {
    [eEthereumNetwork.sepolia]: '0x009c4ba01488A15816093F96BA91210494E2C644', // ledger
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  PoolAdminIndex: 0,
  EmergencyAdminIndex: 0,
  EmergencyAdmin: {
    [eEthereumNetwork.sepolia]: '0x009c4ba01488A15816093F96BA91210494E2C644', // ledger
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  ProviderRegistry: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  ProviderRegistryOwner: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  LendingRateOracle: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  LendingPoolCollateralManager: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  LendingPoolConfigurator: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  LendingPool: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  WethGateway: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  TokenDistributor: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  AaveOracle: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  FallbackOracle: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  ChainlinkAggregator: {
    [eEthereumNetwork.sepolia]: {
      USDC: '0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E',
      XSGD: '0xd9239bB559B8f16DCD67f6186166d218b7514397',
      LP_XSGD_USDC: '0x11686977Ee03B751A15A9E239322cbBbAbc3Baa6', // @todo deploy this
    },
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.kovan]: {},
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.tenderly]: {},
  },
  ReserveAssets: {
    [eEthereumNetwork.sepolia]: {
      USDC: ZERO_ADDRESS,
      XSGD: ZERO_ADDRESS,
      LP_XSGD_USDC: ZERO_ADDRESS,
    },
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.kovan]: {},
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.tenderly]: {},
  },
  ReservesConfig: {},
  ATokenDomainSeparator: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  WETH: {
    [eEthereumNetwork.sepolia]: '0x35da2a468dc7b2c20965235d4a60e2a2a9dace8f',
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  WrappedNativeToken: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  ReserveFactorTreasuryAddress: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
  IncentivesController: {
    [eEthereumNetwork.sepolia]: ZERO_ADDRESS,
    [eEthereumNetwork.coverage]: ZERO_ADDRESS,
    [eEthereumNetwork.buidlerevm]: ZERO_ADDRESS,
    [eEthereumNetwork.kovan]: ZERO_ADDRESS,
    [eEthereumNetwork.ropsten]: ZERO_ADDRESS,
    [eEthereumNetwork.main]: ZERO_ADDRESS,
    [eEthereumNetwork.hardhat]: ZERO_ADDRESS,
    [eEthereumNetwork.tenderly]: ZERO_ADDRESS,
  },
};
