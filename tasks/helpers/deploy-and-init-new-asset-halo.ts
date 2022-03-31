import { task } from 'hardhat/config';
import { eEthereumNetwork } from '../../helpers/types';
import { haloContractAddresses } from '../../helpers/halo-contract-address-network';
import {
  getHaloUiPoolDataProvider,
  getLendingPoolAddressesProvider,
  getLendingPoolConfiguratorProxy,
  getPriceOracle,
  getAaveOracle,
  getATokensAndRatesHelper,
  getFirstSigner,
} from '../../helpers/contracts-getters';
import { getTreasuryAddress } from '../../helpers/configuration';
import * as marketConfigs from '../../markets/halo';
import * as reserveConfigs from '../../markets/halo/reservesConfigs';
import {
  deployDefaultReserveInterestRateStrategy,
  deployStableDebtToken,
  deployVariableDebtToken,
  chooseATokenDeployment,
} from '../../helpers/contracts-deployments';
import { ZERO_ADDRESS } from '../../helpers/constants';

const isSymbolValid = (symbol: string, network: eEthereumNetwork) =>
  Object.keys(reserveConfigs).includes('strategy' + symbol) &&
  marketConfigs.HaloConfig.ReserveAssets[network][symbol] &&
  marketConfigs.HaloConfig.ReservesConfig[symbol] === reserveConfigs['strategy' + symbol];

task(`external:deploy-and-init-new-asset-halo`, `Initialize Asset`)
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify, symbol }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = localBRE.network.name;

    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }
    if (!isSymbolValid(symbol, network as eEthereumNetwork)) {
      throw new Error(
        `
WRONG RESERVE ASSET SETUP:
        The symbol ${symbol} has no reserve Config and/or reserve Asset setup.
        update /markets/halo/index.ts and add the asset address for ${network} network
        update /markets/halo/reservesConfigs.ts and add parameters for ${symbol}
        `
      );
    }

    // deploy new asset

    const strategyParams = reserveConfigs['strategy' + symbol];
    const reserveAssetAddress = marketConfigs.HaloConfig.ReserveAssets[localBRE.network.name][symbol];
    const deployCustomAToken = chooseATokenDeployment(strategyParams.aTokenImpl);
    const addressProvider = await getLendingPoolAddressesProvider(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
    );
    const poolAddress = await addressProvider.getLendingPool();
    const treasuryAddress = await getTreasuryAddress(marketConfigs.HaloConfig);
    const signer = await getFirstSigner();
    console.log(`Deploying ${symbol} reserve asset`);
    console.log(`deployCustomAToken: ${deployCustomAToken}`);
    console.log(`addressProvider: ${addressProvider}`);
    console.log(`Pool address: ${poolAddress}`);
    console.log(`reserveAssetAddress: ${reserveAssetAddress}`);
    console.log(`Deployer: ${await signer.getAddress()}`);

    const aToken = await deployCustomAToken(verify);
    const stableDebt = await deployStableDebtToken(
      [
        poolAddress,
        reserveAssetAddress,
        ZERO_ADDRESS, // Incentives Controller
        `Halo stable debt bearing ${symbol}`,
        `hStableDebt${symbol}`,
      ],
      verify
    );
    const variableDebt = await deployVariableDebtToken(
      [
        poolAddress,
        reserveAssetAddress,
        ZERO_ADDRESS, // Incentives Controller
        `Halo variable debt bearing ${symbol}`,
        `hVariableDebt${symbol}`,
      ],
      verify
    );
    const rates = await deployDefaultReserveInterestRateStrategy(
      [
        addressProvider.address,
        strategyParams.strategy.optimalUtilizationRate,
        strategyParams.strategy.baseVariableBorrowRate,
        strategyParams.strategy.variableRateSlope1,
        strategyParams.strategy.variableRateSlope2,
        strategyParams.strategy.stableRateSlope1,
        strategyParams.strategy.stableRateSlope2,
      ],
      verify
    );
    console.log(`
    New interest bearing asset deployed on ${network}:
    Interest bearing a${symbol} address: ${aToken.address}
    Variable Debt variableDebt${symbol} address: ${variableDebt.address}
    Stable Debt stableDebt${symbol} address: ${stableDebt.address}
    Strategy Implementation for ${symbol} address: ${rates.address}
    `);

    // init new asset

    const uiPoolDataProvider = await getHaloUiPoolDataProvider(
      haloContractAddresses(network).lendingMarket!.protocol.uiHaloPoolDataProvider
    );
    const aaveOracle = await getAaveOracle(haloContractAddresses(network).lendingMarket!.protocol.aaveOracle);
    const priceOracle = await getPriceOracle(haloContractAddresses(network).lendingMarket!.protocol.aaveOracle);
    const lendingPoolConfigurator = await getLendingPoolConfiguratorProxy(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolConfigurator
    );
    const lendingPoolAddressesProvider = await getLendingPoolAddressesProvider(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
    );
    const aTokensAndRatesHelper = await getATokensAndRatesHelper(
      haloContractAddresses(network).lendingMarket!.protocol.aTokensAndRatesHelper
    );

    await aaveOracle.setAssetSources(
      [haloContractAddresses(network).tokens.XSGD!],
      [haloContractAddresses(network).lendingMarket!.priceOracles.fxPHP!]
    );

    console.log('assetPrice', await priceOracle.getAssetPrice(haloContractAddresses(network).tokens.XSGD!));

    await lendingPoolConfigurator.batchInitReserve([
      {
        aTokenImpl: aToken.address,
        stableDebtTokenImpl: stableDebt.address,
        variableDebtTokenImpl: variableDebt.address,
        underlyingAssetDecimals: '6',
        interestRateStrategyAddress: rates.address,
        underlyingAsset: haloContractAddresses(network).tokens.XSGD!,
        treasury: await signer.getAddress(),
        incentivesController: haloContractAddresses(network).lendingMarket!.protocol.rnbwIncentivesController!,
        underlyingAssetName: symbol,
        aTokenName: `h${symbol}`,
        aTokenSymbol: `h${symbol}`,
        variableDebtTokenName: `variable${symbol}`,
        variableDebtTokenSymbol: `variable${symbol}`,
        stableDebtTokenName: `stb${symbol}`,
        stableDebtTokenSymbol: `stb${symbol}`,
        params: '0x10',
      },
    ]);
    console.log(
      await uiPoolDataProvider.getReservesData(
        haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
      )
    );

    await lendingPoolAddressesProvider.setPoolAdmin(
      haloContractAddresses(network).lendingMarket!.protocol.aTokensAndRatesHelper
    );

    const reserveConfig = [
      {
        asset: haloContractAddresses(network).tokens.XSGD!,
        baseLTV: '8000',
        liquidationThreshold: '8500',
        liquidationBonus: '10500',
        reserveFactor: '1000',
        stableBorrowingEnabled: true,
        borrowingEnabled: true,
      },
    ];

    console.log(await aTokensAndRatesHelper.configureReserves(reserveConfig));
    await addressProvider.setPoolAdmin(await signer.getAddress());
    console.log('Pool Admin', await addressProvider.getPoolAdmin());
  });
