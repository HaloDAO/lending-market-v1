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
  deployRnbwIncentivesContoller,
  deployMockParaSwapAugustus,
  deployMockParaSwapAugustusRegistry,
  deployParaSwapLiquiditySwapAdapter,
  authorizeWETHGateway,
  deployUniswapV2Factory,
  deployATokenImplementations,
  deployAaveOracle,
  deployUiPoolDataProvider,
} from '../../helpers/contracts-deployments';
import { eEthereumNetwork, HaloTokenContractId } from '../../helpers/types';
import { ethers, Signer } from 'ethers';
import { TokenContractId, eContractid, tEthereumAddress, AavePools } from '../../helpers/types';
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
import AaveConfig from '../../markets/aave';
import { oneEther, ZERO_ADDRESS } from '../../helpers/constants';
import {
  getLendingPool,
  getLendingPoolConfiguratorProxy,
  getPairsTokenAggregator,
} from '../../helpers/contracts-getters';
import { WETH9Mocked } from '../../types/WETH9Mocked';
import { verify } from 'crypto';

const MOCK_USD_PRICE_IN_WEI = HaloConfig.ProtocolGlobalParams.MockUsdPriceInWei;
const ALL_ASSETS_INITIAL_PRICES = HaloConfig.Mocks.AllAssetsInitialPrices;
const USD_ADDRESS = HaloConfig.ProtocolGlobalParams.UsdAddress;
const MOCK_CHAINLINK_AGGREGATORS_PRICES = HaloConfig.Mocks.AllAssetsInitialPrices;
const LENDING_RATE_ORACLE_RATES_COMMON = HaloConfig.LendingRateOracleRatesCommon;

const deployAllMockTokens = async (deployer: Signer) => {
  const tokens: { [symbol: string]: MockContract | MintableERC20 | WETH9Mocked } = {};

  const protoConfigData = getReservesConfigByPool(AavePools.halo);
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

  const config = loadPoolConfig(ConfigNames.Halo);

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
      WBTC: mockTokens.WBTC.address,
      BUSD: mockTokens.BUSD.address,
      USD: USD_ADDRESS,
      RNBW: mockTokens.RNBW.address,
      // WMATIC: mockTokens.WMATIC.address,
      AAVE: mockTokens.AAVE.address,
      LINK: mockTokens.LINK.address,
      //STAKE: mockTokens.STAKE.address,
      //xSUSHI: mockTokens.xSUSHI.address,
      //WAVAX: mockTokens.WAVAX.address,
    },
    fallbackOracle
  );

  console.log('Oracles deployed');

  //TODO: DOuble check
  const mockAggregators = await deployAllMockAggregators(ALL_ASSETS_INITIAL_PRICES);
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
  const [tokens, aggregators] = getPairsTokenAggregator(allTokenAddresses, allAggregatorsAddresses, 'ETH');
  console.log('Got pair token Aggregator');
  const aaveOracle = await deployAaveOracle([
    tokens,
    aggregators,
    fallbackOracle.address,
    mockTokens.WETH.address,
    oneEther.toString(),
  ]);
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

  const reservesParams = getReservesConfigByPool(AavePools.halo);

  //const reservesParams = {
  //  ...config.ReservesConfig,
  //};

  const testHelpers = await deployAaveProtocolDataProvider(addressesProvider.address);
  await insertContractAddressInDb(eContractid.AaveProtocolDataProvider, testHelpers.address);
  await deployATokenImplementations(ConfigNames.Halo, reservesParams, false);

  const admin = await deployer.getAddress();

  console.log('Initialize configuration');

  const { ATokenNamePrefix, StableDebtTokenNamePrefix, VariableDebtTokenNamePrefix, SymbolPrefix } = config;

  const distributionDuration = '1000000000000';

  // Deploy HALO Tokens
  const rnbwToken = await deployRnbwMock(['Rainbow', 'RNBW']);
  const vestingContractMock = await deployVestingContractMock([rnbwToken.address]);

  // Deploy AMM Mock
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

  // HALO Lending Market Contracts Mock
  const treasury = await deployTreasury([
    lendingPoolAddress,
    rnbwToken.address,
    vestingContractMock.address,
    curveFactoryMock.address,
    mockTokens.USDC.address,
    await uniswapV2Factory.getPair(rnbwToken.address, mockTokens.USDC.address),
  ]);

  const rnbwIncentivesController = await deployRnbwIncentivesContoller([
    rnbwToken.address,
    await deployer.getAddress(),
    distributionDuration,
  ]);

  console.log('HALO Contracts deployed');
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
    ConfigNames.Halo,
    false
  );

  console.log('reserves initialized. configuring reserves');

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

  const augustus = await deployMockParaSwapAugustus();

  const augustusRegistry = await deployMockParaSwapAugustusRegistry([augustus.address]);

  await deployParaSwapLiquiditySwapAdapter([addressesProvider.address, augustusRegistry.address]);

  const uiPoolDataProvider = await deployUiPoolDataProvider(
    [rnbwIncentivesController.address, aaveOracle.address],
    false
  );

  await deployWalletBalancerProvider();
  const gateWay = await deployWETHGateway([mockTokens.WETH.address]);
  await authorizeWETHGateway(gateWay.address, lendingPoolAddress);
  await insertContractAddressInDb(eContractid.UiPoolDataProvider, uiPoolDataProvider.address);
  console.log('setup done');
};

before(async () => {
  await rawBRE.run('set-DRE');
  const [deployer, secondaryWallet, rewardsVault, ...restWallets] = await getEthersSigners();
  const FORK = process.env.FORK;

  if (FORK) {
    await rawBRE.run('aave:mainnet', { skipRegistry: true });
  } else {
    console.log('-> Deploying test environment...');
    await buildTestEnv(deployer, secondaryWallet, rewardsVault);
  }
  await initializeMakeSuite();
  console.log('\n***************');
  console.log('Setup and snapshot finished');
  console.log('***************\n');
});
