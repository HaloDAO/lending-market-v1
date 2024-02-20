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

task('xave:avax-lendingpool-2-a', 'Deploy lending pool for prod enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');

    const addressesProvider = await getLendingPoolAddressesProvider();
    const lendingPoolImpl = await deployLendingPool(verify);
    console.log('deploying lending pool implementation');
    const poolConfig = loadPoolConfig(ConfigNames.XaveAvalache);

    // Set lending pool impl to Address Provider
    console.log('setting lending pool implementation');
    await waitForTx(await addressesProvider.setLendingPoolImpl(lendingPoolImpl.address));
    console.log('lending pool impl set');

    const address = await addressesProvider.getLendingPool();
    const lendingPoolProxy = await getLendingPool(address);

    await insertContractAddressInDb(eContractid.LendingPool, lendingPoolProxy.address);
    console.log('new lending pool proxy in db');

    console.log('deploying lending pool configurator');
    const lendingPoolConfiguratorImpl = await deployLendingPoolConfigurator(verify);
    console.log('lending pool configurator deployed');

    // Set lending pool conf impl to Address Provider
    console.log('setting lending pool configurator implementation');
    await waitForTx(await addressesProvider.setLendingPoolConfiguratorImpl(lendingPoolConfiguratorImpl.address));
    console.log('lending pool configurator proxy set');

    const lendingPoolConfiguratorProxy = await getLendingPoolConfiguratorProxy(
      await addressesProvider.getLendingPoolConfigurator()
    );
    await insertContractAddressInDb(eContractid.LendingPoolConfigurator, lendingPoolConfiguratorProxy.address);

    console.log('new lending pool configurator proxy in db');

    console.log(`
    LendingPoolProxy: ${lendingPoolProxy.address}
    LendingPoolConfiguratorImpl: ${lendingPoolConfiguratorImpl.address}
    LendingPoolConfiguratorProxy: ${lendingPoolConfiguratorProxy.address}
    `);
  });
