import { task } from 'hardhat/config';
import { deployPriceOracle, deployAaveOracle, deployLendingRateOracle } from '../../helpers/contracts-deployments';
import {
  setInitialAssetPricesInOracle,
  deployAllMockAggregators,
  setInitialMarketRatesInRatesOracleByHelper,
} from '../../helpers/oracles-helpers';
import {
  ICommonConfiguration,
  iAssetBase,
  HaloTokenContractId,
  HaloTokenMainetContractId,
  SymbolMap,
} from '../../helpers/types';
import { waitForTx } from '../../helpers/misc-utils';
import { getAllAggregatorsAddresses, getAllTokenAddresses } from '../../helpers/mock-helpers';
import {
  ConfigNames,
  loadPoolConfig,
  getWethAddress,
  getQuoteCurrency,
  getLendingRateOracles,
} from '../../helpers/configuration';
import {
  getAllHaloMockedTokens,
  getAllHaloTokens,
  getLendingPoolAddressesProvider,
  getPairsTokenAggregator,
} from '../../helpers/contracts-getters';
import HaloConfig from '../../markets/halo';
import { getParamPerNetwork } from '../../helpers/contracts-helpers';
import { parseEther } from 'ethers/lib/utils';

task('halo:dev:deploy-oracles', 'Deploy oracles for dev enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .addParam('pool', `Pool name to retrieve configuration, supported: ${Object.values(ConfigNames)}`)
  .setAction(async ({ verify, pool }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = <eNetwork>DRE.network.name;
    const poolConfig = loadPoolConfig(pool);
    const {
      ProtocolGlobalParams: { UsdAddress },
      ReserveAssets,
      FallbackOracle,
      ChainlinkAggregator,
    } = poolConfig as ICommonConfiguration;

    const reserveAssets = await getParamPerNetwork(ReserveAssets, network);
    const addressesProvider = await getLendingPoolAddressesProvider();
    const admin = await addressesProvider.getPoolAdmin();

    // 1 - Get custom configuration for mainet support
    const tokensToWatch: SymbolMap<string> = {
      ...reserveAssets,
      USD: UsdAddress,
    };

    const chainlinkAggregators = await getParamPerNetwork(ChainlinkAggregator, network);
    const lendingRateOracles = getLendingRateOracles(poolConfig);
    const [tokens, aggregators] = getPairsTokenAggregator(
      tokensToWatch,
      chainlinkAggregators,
      poolConfig.OracleQuoteCurrency
    );

    const fallbackOracle = await deployPriceOracle(verify);
    await waitForTx(await fallbackOracle.setEthUsdPrice(parseEther('4044')));

    const aaveOracle = await deployAaveOracle(
      [tokens, aggregators, fallbackOracle.address, await getQuoteCurrency(poolConfig), poolConfig.OracleQuoteUnit],
      verify
    );

    const lendingRateOracle = await deployLendingRateOracle(verify);
    const { USD, ...tokensAddressesWithoutUsd } = tokensToWatch;

    await setInitialMarketRatesInRatesOracleByHelper(
      lendingRateOracles,
      tokensAddressesWithoutUsd,
      lendingRateOracle,
      admin
    );
    await waitForTx(await aaveOracle.setAssetSources(tokens, aggregators));
    await waitForTx(await addressesProvider.setPriceOracle(aaveOracle.address));
    await waitForTx(await addressesProvider.setLendingRateOracle(lendingRateOracle.address));

    await setInitialMarketRatesInRatesOracleByHelper(
      lendingRateOracles,
      tokensAddressesWithoutUsd,
      lendingRateOracle,
      admin
    );

    const allReservesAddresses = {
      ...tokensAddressesWithoutUsd,
    };
  });
