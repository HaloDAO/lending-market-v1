import { task } from 'hardhat/config';
import { eEthereumNetwork } from '../../helpers/types';
import {
  haloContractAddresses,
  underlyingAssetAddress,
  priceOracleAddress,
} from '../../helpers/halo-contract-address-network';
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

task(`external:deploy-and-init-new-asset-halo`, `Deploy and Initialize Asset`)
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify, symbol, decimal }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = localBRE.network.name;

    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }
    if (!decimal) {
      throw new Error('INVALID_DECIMAL');
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

    const isUnderlyingAssetAddressValid = underlyingAssetAddress(network, symbol) !== '' ? true : false;
    const isPriceOracleAddressValid = priceOracleAddress(network, symbol) !== '' ? true : false;

    if (!isUnderlyingAssetAddressValid) {
      throw new Error(
        `
UNDERLYING ASSET ADDRESS NOT FOUND:
        The symbol ${symbol} has no matching token address in halodao-contract-addresses package.
        `
      );
    }

    if (!isPriceOracleAddressValid) {
      throw new Error(
        `
PRICE ORACLE ADDRESS NOT FOUND:
        The symbol ${symbol} has no matching priceOracle address in halodao-contract-addresses package.
        `
      );
    }

    // deploy new asset

    const strategyParams = reserveConfigs['strategy' + symbol];
    const reserveAssetAddress = marketConfigs.HaloConfig.ReserveAssets[localBRE.network.name][symbol];
    const deployCustomAToken = chooseATokenDeployment(strategyParams.aTokenImpl);
    const addressProviderContract = await getLendingPoolAddressesProvider(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
    );
    const poolAddress = await addressProviderContract.getLendingPool();
    const treasuryAddress = await getTreasuryAddress(marketConfigs.HaloConfig);
    const signer = await getFirstSigner();
    console.log(`Deploying ${symbol} reserve asset`);
    console.log(`deployCustomAToken: ${deployCustomAToken}`);
    console.log(`addressProvider: ${addressProviderContract}`);
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
        addressProviderContract.address,
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

    const aaveOracleContract = await getAaveOracle(haloContractAddresses(network).lendingMarket!.protocol.aaveOracle);
    const priceOracleContract = await getPriceOracle(haloContractAddresses(network).lendingMarket!.protocol.aaveOracle);
    const lendingPoolConfiguratorContract = await getLendingPoolConfiguratorProxy(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolConfigurator
    );
    const uiPoolDataProviderContractContract = await getHaloUiPoolDataProvider(
      haloContractAddresses(network).lendingMarket!.protocol.uiHaloPoolDataProvider
    );
    const aTokensAndRatesHelperContract = await getATokensAndRatesHelper(
      haloContractAddresses(network).lendingMarket!.protocol.aTokensAndRatesHelper
    );

    await aaveOracleContract.setAssetSources(
      [underlyingAssetAddress(network, symbol)],
      [priceOracleAddress(network, symbol)]
    );

    console.log('assetPrice', await priceOracleContract.getAssetPrice(underlyingAssetAddress(network, symbol)));

    await lendingPoolConfiguratorContract.batchInitReserve([
      {
        aTokenImpl: aToken.address,
        stableDebtTokenImpl: stableDebt.address,
        variableDebtTokenImpl: variableDebt.address,
        underlyingAssetDecimals: decimal,
        interestRateStrategyAddress: rates.address,
        underlyingAsset: underlyingAssetAddress(network, symbol),
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
      await uiPoolDataProviderContractContract.getReservesData(
        haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
      )
    );

    await addressProviderContract.setPoolAdmin(
      haloContractAddresses(network).lendingMarket!.protocol.aTokensAndRatesHelper
    );

    const reserveConfig = [
      {
        asset: underlyingAssetAddress(network, symbol),
        baseLTV: '8000',
        liquidationThreshold: '8500',
        liquidationBonus: '10500',
        reserveFactor: '1000',
        stableBorrowingEnabled: true,
        borrowingEnabled: true,
      },
    ];

    console.log(await aTokensAndRatesHelperContract.configureReserves(reserveConfig));
    await addressProviderContract.setPoolAdmin(await signer.getAddress());
    console.log('Pool Admin is set back to deployer: ', await addressProviderContract.getPoolAdmin());
  });
