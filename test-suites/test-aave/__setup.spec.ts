import rawBRE from 'hardhat';
import { MockContract } from 'ethereum-waffle';
import BigNumber from 'bignumber.js';
import {
  insertContractAddressInDb,
  getEthersSigners,
  registerContractInJsonDb,
  getEthersSignersAddresses,
} from '../../helpers/contracts-helpers';
import {
  deployLendingPoolAddressesProvider,
  deployMintableERC20,
  deployLendingPoolAddressesProviderRegistry,
  deployLendingPoolConfigurator,
  deployLendingPool,
  deployPriceOracle,
  deployAaveOracle,
  deployLendingPoolCollateralManager,
  deployMockFlashLoanReceiver,
  deployWalletBalancerProvider,
  deployAaveProtocolDataProvider,
  deployLendingRateOracle,
  deployStableAndVariableTokensHelper,
  deployATokensAndRatesHelper,
  deployWETHGateway,
  deployWETHMocked,
  deployMockUniswapRouter,
  deployUniswapLiquiditySwapAdapter,
  deployUniswapRepayAdapter,
  deployFlashLiquidationAdapter,
  deployRnbwMock,
  deployTreasury,
  deployVestingContractMock,
  deployCurveMock,
  deployCurveFactoryMock,
  deployMockEmissionManager,
  deployRnbwIncentivesContoller,
  authorizeWETHGateway,
  deployUniswapV2Factory,
  deployUiPoolDataProvider,
} from '../../helpers/contracts-deployments';
import { eEthereumNetwork, HaloTokenContractId } from '../../helpers/types';
import { ethers, Signer } from 'ethers';
import { eContractid, tEthereumAddress, AavePools } from '../../helpers/types';
import { MintableERC20 } from '../../types/MintableERC20';
import { ConfigNames, getReservesConfigByPool, getTreasuryAddress, loadPoolConfig } from '../../helpers/configuration';
import { initializeMakeSuite } from './helpers/make-suite';
import { deployMockContract } from '@ethereum-waffle/mock-contract';

import {
  setInitialAssetPricesInOracle,
  deployAllMockAggregators,
  setInitialMarketRatesInRatesOracleByHelper,
} from '../../helpers/oracles-helpers';
import { waitForTx } from '../../helpers/misc-utils';
import { initReservesByHelper, configureReservesByHelper } from '../../helpers/init-helpers';
import HaloConfig from '../../markets/halo';
import {
  getLendingPool,
  getLendingPoolConfiguratorProxy,
  getPairsTokenAggregator,
} from '../../helpers/contracts-getters';
import { WETH9Mocked } from '../../types/WETH9Mocked';

const MOCK_USD_PRICE_IN_WEI = HaloConfig.ProtocolGlobalParams.MockUsdPriceInWei;
const ALL_ASSETS_INITIAL_PRICES = HaloConfig.Mocks.AllAssetsInitialPrices;
const USD_ADDRESS = HaloConfig.ProtocolGlobalParams.UsdAddress;
const MOCK_CHAINLINK_AGGREGATORS_PRICES = HaloConfig.Mocks.AllAssetsInitialPrices;
const LENDING_RATE_ORACLE_RATES_COMMON = HaloConfig.LendingRateOracleRatesCommon;

const deployAllMockTokens = async (deployer: Signer) => {
  const tokens: { [symbol: string]: MockContract | MintableERC20 | WETH9Mocked } = {};

  const protoConfigData = getReservesConfigByPool(AavePools.proto);
  for (const tokenSymbol of Object.keys(HaloTokenContractId)) {
    if (tokenSymbol === 'WETH') {
      tokens[tokenSymbol] = await deployWETHMocked();
      await registerContractInJsonDb(tokenSymbol.toUpperCase(), tokens[tokenSymbol]);
      continue;
    }
    let decimals = 18;

    let configData = (<any>protoConfigData)[tokenSymbol];

    if (!configData) {
      decimals = 18;
    }

    tokens[tokenSymbol] = await deployMintableERC20([
      tokenSymbol,
      tokenSymbol,
      configData ? configData.reserveDecimals : 18,
    ]);
    await registerContractInJsonDb(tokenSymbol.toUpperCase(), tokens[tokenSymbol]);
  }

  return tokens;
};

const buildTestEnv = async (deployer: Signer, secondaryWallet: Signer, rewardsVault: Signer) => {
  const aaveAdmin = await deployer.getAddress();

  const mockTokens = await deployAllMockTokens(deployer);
  console.log('Deployed mocks');

  const addressesProvider = await deployLendingPoolAddressesProvider(HaloConfig.MarketId);
  await waitForTx(await addressesProvider.setPoolAdmin(aaveAdmin));

  //setting users[1] as emergency admin, which is in position 2 in the DRE addresses list
  const addressList = await getEthersSignersAddresses();
  await waitForTx(await addressesProvider.setEmergencyAdmin(addressList[2]));

  const addressesProviderRegistry = await deployLendingPoolAddressesProviderRegistry();
  await waitForTx(await addressesProviderRegistry.registerAddressesProvider(addressesProvider.address, 1));

  const lendingPoolImpl = await deployLendingPool();

  await waitForTx(await addressesProvider.setLendingPoolImpl(lendingPoolImpl.address));

  const lendingPoolAddress = await addressesProvider.getLendingPool();
  const lendingPoolProxy = await getLendingPool(lendingPoolAddress);

  await insertContractAddressInDb(eContractid.LendingPool, lendingPoolProxy.address);

  const lendingPoolConfiguratorImpl = await deployLendingPoolConfigurator();
  await waitForTx(await addressesProvider.setLendingPoolConfiguratorImpl(lendingPoolConfiguratorImpl.address));
  const lendingPoolConfiguratorProxy = await getLendingPoolConfiguratorProxy(
    await addressesProvider.getLendingPoolConfigurator()
  );
  await insertContractAddressInDb(eContractid.LendingPoolConfigurator, lendingPoolConfiguratorProxy.address);

  // Deploy deployment helpers
  await deployStableAndVariableTokensHelper([lendingPoolProxy.address, addressesProvider.address]);
  await deployATokensAndRatesHelper([
    lendingPoolProxy.address,
    addressesProvider.address,
    lendingPoolConfiguratorProxy.address,
  ]);

  const fallbackOracle = await deployPriceOracle();
  await waitForTx(await fallbackOracle.setEthUsdPrice(MOCK_USD_PRICE_IN_WEI));

  await setInitialAssetPricesInOracle(
    ALL_ASSETS_INITIAL_PRICES,
    {
      WETH: mockTokens.WETH.address,
      DAI: mockTokens.DAI.address,
      XSGD: mockTokens.XSGD.address,
      THKD: mockTokens.THKD.address,
      TUSD: mockTokens.TUSD.address,
      USDC: mockTokens.USDC.address,
      USDT: mockTokens.USDT.address,
      SUSD: mockTokens.SUSD.address,
      AAVE: mockTokens.AAVE.address,
      WBTC: mockTokens.WBTC.address,
      BUSD: mockTokens.BUSD.address,
      USD: USD_ADDRESS,
      RNBW: mockTokens.RNBW.address,
      //WMATIC: mockTokens.WMATIC.address,
    },
    fallbackOracle
  );

  console.log('Oracles deployed');

  const mockAggregators = await deployAllMockAggregators(MOCK_CHAINLINK_AGGREGATORS_PRICES);
  console.log('Mock aggs deployed');

  const allTokenAddresses = Object.entries(mockTokens).reduce(
    (accum: { [tokenSymbol: string]: tEthereumAddress }, [tokenSymbol, tokenContract]) => ({
      ...accum,
      [tokenSymbol]: tokenContract.address,
    }),
    {}
  );
  const allAggregatorsAddresses = Object.entries(mockAggregators).reduce(
    (accum: { [tokenSymbol: string]: tEthereumAddress }, [tokenSymbol, aggregator]) => ({
      ...accum,
      [tokenSymbol]: aggregator.address,
    }),
    {}
  );

  console.log('Token addresses and aggregators set');
  const [tokens, aggregators] = getPairsTokenAggregator(allTokenAddresses, allAggregatorsAddresses);
  console.log('Got pair token Aggregator');
  const aaveOracle = await deployAaveOracle([tokens, aggregators, fallbackOracle.address, mockTokens.WETH.address]);
  console.log('Aave Oracle deployed');
  await waitForTx(await addressesProvider.setPriceOracle(fallbackOracle.address));
  console.log('Fallback Aave Oracle set in addresses provider');

  const lendingRateOracle = await deployLendingRateOracle();
  console.log('lending rate oracle deployed');
  await waitForTx(await addressesProvider.setLendingRateOracle(lendingRateOracle.address));
  console.log('lending oracle set');
  const { USD, ...tokensAddressesWithoutUsd } = allTokenAddresses;
  const allReservesAddresses = {
    ...tokensAddressesWithoutUsd,
  };
  await setInitialMarketRatesInRatesOracleByHelper(
    LENDING_RATE_ORACLE_RATES_COMMON,
    allReservesAddresses,
    lendingRateOracle,
    aaveAdmin
  );

  console.log('Initial market rates in rates oracle set');
  //await setInitialMarketRatesInRatesOracleByHelper(
  //  LENDING_RATE_ORACLE_RATES_COMMON,
  //  allReservesAddresses,
  //  lendingRateOracle,
  //  aaveAdmin
  //);

  const reservesParams = getReservesConfigByPool(AavePools.halo);
  const testHelpers = await deployAaveProtocolDataProvider(addressesProvider.address);
  await insertContractAddressInDb(eContractid.AaveProtocolDataProvider, testHelpers.address);
  const admin = await deployer.getAddress();
  console.log('Initialize configuration');
  const config = loadPoolConfig(ConfigNames.Halo);
  const { ATokenNamePrefix, StableDebtTokenNamePrefix, VariableDebtTokenNamePrefix, SymbolPrefix } = config;
  //const treasuryAddress = await getTreasuryAddress(config);
  // await initReservesByHelper(
  //   reservesParams,
  //   allReservesAddresses,
  //   ATokenNamePrefix,
  //   StableDebtTokenNamePrefix,
  //   VariableDebtTokenNamePrefix,
  //   SymbolPrefix,
  //   admin,
  //   treasuryAddress,
  //   ZERO_ADDRESS,
  //   false
  // );
  const distributionDuration = '1000000000000';
  const rnbwToken = await deployRnbwMock(['Rainbow', 'RNBW']);
  const vestingContractMock = await deployVestingContractMock([rnbwToken.address]);
  const oneEther = new BigNumber(Math.pow(10, 18));
  const curveMockDai = await deployCurveMock([mockTokens.USDC.address, mockTokens.DAI.address, oneEther.toFixed()]);

  const curveMockSGD = await deployCurveMock([mockTokens.USDC.address, mockTokens.XSGD.address, oneEther.toFixed()]);
  const curveFactoryMock = await deployCurveFactoryMock([
    mockTokens.USDC.address,
    [mockTokens.DAI.address, mockTokens.XSGD.address],
    [curveMockDai.address, curveMockSGD.address],
  ]);

  // SLP Deployments
  const uniswapV2Factory = await deployUniswapV2Factory([await deployer.getAddress()]);
  await uniswapV2Factory.createPair(rnbwToken.address, mockTokens.USDC.address);

  const treasury = await deployTreasury([
    lendingPoolAddress,
    rnbwToken.address,
    vestingContractMock.address,
    curveFactoryMock.address,
    mockTokens.USDC.address,
    await uniswapV2Factory.getPair(rnbwToken.address, mockTokens.USDC.address),
  ]);

  const mockEmissionManager = await deployMockEmissionManager([]);
  const rnbwIncentivesController = await deployRnbwIncentivesContoller([
    rnbwToken.address,
    await deployer.getAddress(),
    distributionDuration,
  ]);
  await mockEmissionManager.setIncentivesController(rnbwIncentivesController.address);

  await initReservesByHelper(
    reservesParams,
    allReservesAddresses,
    ATokenNamePrefix,
    StableDebtTokenNamePrefix,
    VariableDebtTokenNamePrefix,
    SymbolPrefix,
    admin,
    treasury.address,
    rnbwIncentivesController.address,
    false
  );

  await configureReservesByHelper(reservesParams, allReservesAddresses, testHelpers, admin);

  const collateralManager = await deployLendingPoolCollateralManager();
  await waitForTx(await addressesProvider.setLendingPoolCollateralManager(collateralManager.address));
  await deployMockFlashLoanReceiver(addressesProvider.address);

  const mockUniswapRouter = await deployMockUniswapRouter();

  const adapterParams: [string, string, string] = [
    addressesProvider.address,
    mockUniswapRouter.address,
    mockTokens.WETH.address,
  ];
  await deployUniswapLiquiditySwapAdapter(adapterParams);
  await deployUniswapRepayAdapter(adapterParams);
  await deployFlashLiquidationAdapter(adapterParams);

  const uiPoolDataProvider = await deployUiPoolDataProvider(
    [rnbwIncentivesController.address, aaveOracle.address],
    false
  );

  await deployWalletBalancerProvider();
  const gateWay = await deployWETHGateway([mockTokens.WETH.address]);
  await authorizeWETHGateway(gateWay.address, lendingPoolAddress);
  console.timeEnd('setup');
};

before(async () => {
  await rawBRE.run('set-DRE');
  const [deployer, secondaryWallet, rewardsVault, ...restWallets] = await getEthersSigners();
  const FORK = process.env.FORK;

  if (FORK) {
    await rawBRE.run('aave:mainnet');
  } else {
    console.log('-> Deploying test environment...');
    await buildTestEnv(deployer, secondaryWallet, rewardsVault);
  }
  await initializeMakeSuite();
  console.log('\n***************');
  console.log('Setup and snapshot finished');
  console.log('***************\n');
});
