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
    const addressProvider = await getLendingPoolAddressesProvider('0x59847B1314E1A1cad9E0a207F6E53c04F4FAbFBD');

    // const assetAddress = getAssetAddress(lp, network, symbol);
    const assetAddress = '0x9649201B51de91E059076329531347a9e615ABC8';

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
    const uiPoolDataProvider = await getHaloUiPoolDataProvider('0x8D0b93D929115faA2499DCF6Cfc84123ff9DC5Cd');
    const aaveOracle = await getAaveOracle('0x3fa5F6aD2Afc55Fc117F19B06A7F436dE9a047e9');
    const lendingPoolConfigurator = await getLendingPoolConfiguratorProxy('0x648DE21130Cf2b8B885EA06C7e755598Cc1eEE21');

    console.log('settting asset');

    const properSymbol = symbol === 'MockUSDC' ? 'USDC' : symbol;
    await aaveOracle.setAssetSources([assetAddress], ['0x84713bcc6aee40b908b0ad3e946cec80278e87f1']);

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
        incentivesController: '0x9f180428AB4fa85df1D2Fb6DE6527059D60d8D60',
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
    console.log(await uiPoolDataProvider.getReservesData('0x59847B1314E1A1cad9E0a207F6E53c04F4FAbFBD'));

    console.log('Reserve initialization complete. Configuring reserve..');
  });
