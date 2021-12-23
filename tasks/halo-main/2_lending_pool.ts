import { task } from 'hardhat/config';
import {
  deployATokenImplementations,
  deployATokensAndRatesHelper,
  deployLendingPool,
  deployLendingPoolConfigurator,
  deployStableAndVariableTokensHelper,
} from '../../helpers/contracts-deployments';
import { eContractid } from '../../helpers/types';
import { printContracts, waitForTx } from '../../helpers/misc-utils';
import {
  getLendingPoolAddressesProvider,
  getLendingPool,
  getLendingPoolConfiguratorProxy,
} from '../../helpers/contracts-getters';
import { insertContractAddressInDb } from '../../helpers/contracts-helpers';
import { ConfigNames, loadPoolConfig } from '../../helpers/configuration';

task('halo:mainnet-2', 'Deploy lending pool for prod enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');

    const addressesProvider = await getLendingPoolAddressesProvider();
    const lendingPoolImpl = await deployLendingPool(verify);
    const poolConfig = loadPoolConfig(ConfigNames.Halo);

    // Set lending pool impl to Address Provider
    await waitForTx(await addressesProvider.setLendingPoolImpl(lendingPoolImpl.address));

    const address = await addressesProvider.getLendingPool();
    const lendingPoolProxy = await getLendingPool(address);

    await insertContractAddressInDb(eContractid.LendingPool, lendingPoolProxy.address);

    const lendingPoolConfiguratorImpl = await deployLendingPoolConfigurator(verify);

    // Set lending pool conf impl to Address Provider
    await waitForTx(await addressesProvider.setLendingPoolConfiguratorImpl(lendingPoolConfiguratorImpl.address));

    const lendingPoolConfiguratorProxy = await getLendingPoolConfiguratorProxy(
      await addressesProvider.getLendingPoolConfigurator()
    );
    await insertContractAddressInDb(eContractid.LendingPoolConfigurator, lendingPoolConfiguratorProxy.address);

    // Deploy deployment helper contracts
    const stableAndVariableTokensHelper = await deployStableAndVariableTokensHelper(
      [lendingPoolProxy.address, addressesProvider.address],
      verify
    );
    const aTokensAndRatesHelper = await deployATokensAndRatesHelper(
      [lendingPoolProxy.address, addressesProvider.address, lendingPoolConfiguratorProxy.address],
      verify
    );

    await deployATokenImplementations(ConfigNames.Halo, poolConfig.ReservesConfig, verify);

    console.log(`
    LendingPoolProxy: ${lendingPoolProxy.address}
    LendingPoolConfiguratorImpl: ${lendingPoolConfiguratorImpl.address}
    LendingPoolConfiguratorProxy: ${lendingPoolConfiguratorProxy.address}
    StableAndVariableTokensHelper: ${stableAndVariableTokensHelper.address}
    aTokensAndRatesHelper: ${aTokensAndRatesHelper.address}
    `);
  });
