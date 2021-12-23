import { task } from 'hardhat/config';
import { deployAaveOracle, deployLendingRateOracle } from '../../helpers/contracts-deployments';
import { setInitialMarketRatesInRatesOracleByHelper } from '../../helpers/oracles-helpers';
import { eNetwork, ICommonConfiguration, SymbolMap } from '../../helpers/types';
import { DRE, waitForTx } from '../../helpers/misc-utils';
import { ConfigNames, loadPoolConfig, getQuoteCurrency, getLendingRateOracles } from '../../helpers/configuration';
import { getLendingPoolAddressesProvider, getPairsTokenAggregator } from '../../helpers/contracts-getters';
import { getParamPerNetwork } from '../../helpers/contracts-helpers';
import { HALO_CONTRACT_ADDRESSES } from '../../markets/halo/constants';

task('halo:mainnet-3', 'Deploy oracles for prod enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = <eNetwork>DRE.network.name;
    const poolConfig = loadPoolConfig(ConfigNames.Halo);
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

    console.log(`
    AaveOracle: ${aaveOracle.address}
    LendingRateOracle: ${lendingRateOracle.address}
    `);
  });
