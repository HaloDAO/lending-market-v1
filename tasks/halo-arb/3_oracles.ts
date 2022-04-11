import { task } from 'hardhat/config';
import { deployAaveOracle, deployLendingRateOracle } from '../../helpers/contracts-deployments';
import { setInitialMarketRatesInRatesOracleByHelper } from '../../helpers/oracles-helpers';
import { eNetwork, ICommonConfiguration, SymbolMap } from '../../helpers/types';
import { DRE, waitForTx } from '../../helpers/misc-utils';
import { ConfigNames, loadPoolConfig, getQuoteCurrency, getLendingRateOracles } from '../../helpers/configuration';
import { getLendingPoolAddressesProvider, getPairsTokenAggregator } from '../../helpers/contracts-getters';
import { getParamPerNetwork } from '../../helpers/contracts-helpers';
import { HALO_CONTRACT_ADDRESSES } from '../../markets/halo-arb/constants';

task('halo:arb-oracles-3', 'Deploy oracles for prod enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = <eNetwork>DRE.network.name;
    const poolConfig = loadPoolConfig(ConfigNames.HaloArb);
    const {
      ProtocolGlobalParams: { UsdAddress },
      ReserveAssets,
      //FallbackOracle,
      ChainlinkAggregator,
    } = poolConfig as ICommonConfiguration;

    const reserveAssets = await getParamPerNetwork(ReserveAssets, network);
    const addressesProvider = await getLendingPoolAddressesProvider();
    const admin = await addressesProvider.getPoolAdmin();

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

    console.log('before deploying aaveOracle');
    const aaveOracle = await deployAaveOracle(
      [
        tokens,
        aggregators,
        HALO_CONTRACT_ADDRESSES[network].fallbackPriceOracle,
        await getQuoteCurrency(poolConfig),
        poolConfig.OracleQuoteUnit,
      ],
      verify
    );

    console.log('deployed aave oracle');

    const lendingRateOracle = await deployLendingRateOracle(verify);
    console.log('lending rate oracle deployed');
    const { USD, ...tokensAddressesWithoutUsd } = tokensToWatch;

    await setInitialMarketRatesInRatesOracleByHelper(
      lendingRateOracles,
      tokensAddressesWithoutUsd,
      lendingRateOracle,
      admin
    );

    console.log('set initial market rates in oracle');

    await waitForTx(await aaveOracle.setAssetSources(tokens, aggregators));
    console.log('asset sources set in aave oracle');
    await waitForTx(await addressesProvider.setPriceOracle(aaveOracle.address));
    console.log('set oracle price');
    await waitForTx(await addressesProvider.setLendingRateOracle(lendingRateOracle.address));
    console.log('set lending rate oracle');

    await setInitialMarketRatesInRatesOracleByHelper(
      lendingRateOracles,
      tokensAddressesWithoutUsd,
      lendingRateOracle,
      admin
    );

    console.log(`
    AaveOracle: ${aaveOracle.address}
    LendingRateOracle: ${lendingRateOracle.address}
    `);
  });
