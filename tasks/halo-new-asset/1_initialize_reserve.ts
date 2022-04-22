import { task } from 'hardhat/config';
import { eEthereumNetwork } from '../../helpers/types';
import { getTreasuryAddress } from '../../helpers/configuration';
import * as marketConfigs from '../../markets/halo';
import * as reserveConfigs from '../../markets/halo/reservesConfigs';

import {
  getAaveOracle,
  getATokensAndRatesHelper,
  getFirstSigner,
  getHaloUiPoolDataProvider,
  getLendingPoolAddressesProvider,
  getLendingPoolConfiguratorProxy,
  getPriceOracle,
} from '../../helpers/contracts-getters';
import {
  deployDefaultReserveInterestRateStrategy,
  deployStableDebtToken,
  deployVariableDebtToken,
  chooseATokenDeployment,
} from '../../helpers/contracts-deployments';
import { setDRE } from '../../helpers/misc-utils';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { haloContractAddresses } from '../../helpers/halo-contract-address-network';
import { formatEther } from '@ethersproject/units';

const isSymbolValid = (symbol: string, network: eEthereumNetwork) =>
  Object.keys(reserveConfigs).includes('strategy' + symbol) &&
  marketConfigs.HaloConfig.ReserveAssets[network][symbol] &&
  marketConfigs.HaloConfig.ReservesConfig[symbol] === reserveConfigs['strategy' + symbol];

task('halo:newasset:initialize-reserve', 'Initialize reserve')
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify, symbol }, localBRE) => {
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
    const signer = await getFirstSigner();
    const strategyParams = reserveConfigs['strategy' + symbol];
    const reserveAssetAddress = marketConfigs.HaloConfig.ReserveAssets[localBRE.network.name][symbol];
    const deployCustomAToken = chooseATokenDeployment(strategyParams.aTokenImpl);
    const addressProvider = await getLendingPoolAddressesProvider(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
    );

    const poolAddress = await addressProvider.getLendingPool();

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
    const lendingPoolConfigurator = await getLendingPoolConfiguratorProxy('0xCeE5D0fb8fF915D8C089f2B05edF138801E1dB0B');
    const lendingPoolAddressesProvider = await getLendingPoolAddressesProvider(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
    );

    await aaveOracle.setAssetSources(
      [haloContractAddresses(network).tokens[symbol]],
      // [haloContractAddresses(network).lendingMarket!.priceOracles[symbol]]
      ['0xa20623070413d42a5C01Db2c8111640DD7A5A03a'] // USTETH
    );

    console.log(
      'assetPrice: ',
      formatEther(await aaveOracle.getAssetPrice(haloContractAddresses(network).tokens[symbol]))
    );

    await lendingPoolConfigurator.batchInitReserve([
      {
        aTokenImpl: aToken.address,
        stableDebtTokenImpl: stableDebt.address,
        variableDebtTokenImpl: variableDebt.address,
        underlyingAssetDecimals: '6',
        interestRateStrategyAddress: rates.address,
        underlyingAsset: haloContractAddresses(network).tokens[symbol],
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

    console.log('Reserve initialization complete. Configuring reserve..');
  });
