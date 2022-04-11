import { task } from 'hardhat/config';
import {
  deployATokenImplementations,
  deployATokensAndRatesHelper,
  deployLendingPool,
  deployLendingPoolConfigurator,
  deployStableAndVariableTokensHelper,
} from '../../helpers/contracts-deployments';
import { eContractid } from '../../helpers/types';
import { waitForTx } from '../../helpers/misc-utils';
import {
  getLendingPoolAddressesProvider,
  getLendingPool,
  getLendingPoolConfiguratorProxy,
} from '../../helpers/contracts-getters';
import { insertContractAddressInDb } from '../../helpers/contracts-helpers';
import { ConfigNames, loadPoolConfig } from '../../helpers/configuration';

task('halo:arb-lendingpool-2', 'Deploy lending pool for arbitrum enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');

    const addressesProvider = await getLendingPoolAddressesProvider();
    const lendingPoolImpl = await deployLendingPool(verify);
    console.log('deploying lending pool implementation');
    const poolConfig = loadPoolConfig(ConfigNames.Halo);

    // Set lending pool impl to Address Provider
    await waitForTx(await addressesProvider.setLendingPoolImpl(lendingPoolImpl.address));
    console.log('setting lending pool implementation');

    const address = await addressesProvider.getLendingPool();
    const lendingPoolProxy = await getLendingPool(address);

    await insertContractAddressInDb(eContractid.LendingPool, lendingPoolProxy.address);

    const lendingPoolConfiguratorImpl = await deployLendingPoolConfigurator(verify);
    console.log('deploying lending pool configurator');

    // Set lending pool conf impl to Address Provider
    await waitForTx(await addressesProvider.setLendingPoolConfiguratorImpl(lendingPoolConfiguratorImpl.address));
    console.log('setting lending pool configurator implementation');

    const lendingPoolConfiguratorProxy = await getLendingPoolConfiguratorProxy(
      await addressesProvider.getLendingPoolConfigurator()
    );
    await insertContractAddressInDb(eContractid.LendingPoolConfigurator, lendingPoolConfiguratorProxy.address);

    // Deploy deployment helper contracts
    const stableAndVariableTokensHelper = await deployStableAndVariableTokensHelper(
      [lendingPoolProxy.address, addressesProvider.address],
      verify
    );

    console.log('deploying stable and variable tokens helper');
    const aTokensAndRatesHelper = await deployATokensAndRatesHelper(
      [lendingPoolProxy.address, addressesProvider.address, lendingPoolConfiguratorProxy.address],
      verify
    );

    console.log('deploying a tokens and rates helper');

    await deployATokenImplementations(ConfigNames.Halo, poolConfig.ReservesConfig, verify);

    console.log('deploy aToken implementations');

    console.log(`
    LendingPoolProxy: ${lendingPoolProxy.address}
    LendingPoolConfiguratorImpl: ${lendingPoolConfiguratorImpl.address}
    LendingPoolConfiguratorProxy: ${lendingPoolConfiguratorProxy.address}
    StableAndVariableTokensHelper: ${stableAndVariableTokensHelper.address}
    aTokensAndRatesHelper: ${aTokensAndRatesHelper.address}
    `);
  });
