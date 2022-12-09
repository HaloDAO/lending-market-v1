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
  getIErc20Detailed,
  getLendingPoolAddressesProvider,
  getLendingPoolConfiguratorProxy,
  getPriceOracle,
} from '../../helpers/contracts-getters-ledger';

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
import { getAssetAddress } from '../helpers/halo-helpers/util-getters';

const isSymbolValid = (symbol: string, network: eEthereumNetwork) =>
  Object.keys(reserveConfigs).includes('strategy' + symbol) &&
  marketConfigs.HaloConfig.ReserveAssets[network][symbol] &&
  marketConfigs.HaloConfig.ReservesConfig[symbol] === reserveConfigs['strategy' + symbol];

task('halo:newasset:initialize-reserve', 'Initialize reserve')
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('lp', 'If asset is an LP')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify, symbol, lp }, localBRE) => {
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

    const assetAddress = getAssetAddress(lp, network, symbol);

    console.log(`assetAddress is: ${assetAddress} and it is a ${lp ? 'LP token' : 'not a LP token'}`);

    const assetERC20Instance = await getIErc20Detailed(assetAddress);

    const assetDecimals = await assetERC20Instance.decimals();
    console.log('Decimals: ', assetDecimals);

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
    const lendingPoolConfigurator = await getLendingPoolConfiguratorProxy(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolConfigurator
    );

    console.log('settting asset');

    const properSymbol = symbol === 'MockUSDC' ? 'USDC' : symbol;
    await aaveOracle.setAssetSources(
      [assetAddress],
      [haloContractAddresses(network).lendingMarket!.priceOracles[properSymbol]]
    );

    console.log('assetPrice: ', formatEther(await aaveOracle.getAssetPrice(assetAddress)));

    await lendingPoolConfigurator.batchInitReserve([
      {
        aTokenImpl: aToken.address,
        stableDebtTokenImpl: stableDebt.address,
        variableDebtTokenImpl: variableDebt.address,
        underlyingAssetDecimals: assetDecimals, // change
        interestRateStrategyAddress: rates.address,
        underlyingAsset: assetAddress, // change
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
