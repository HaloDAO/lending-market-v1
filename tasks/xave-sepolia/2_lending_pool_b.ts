import { task } from 'hardhat/config';
import {
  deployATokenImplementations,
  deployATokensAndRatesHelper,
  deployLendingPool,
  deployLendingPoolConfigurator,
  deployStableAndVariableTokensHelper,
} from '../../helpers/contracts-deployments-ledger-ledger';
import { eContractid } from '../../helpers/types';
import { waitForTx } from '../../helpers/misc-utils';
import {
  getLendingPoolAddressesProvider,
  getLendingPool,
  getLendingPoolConfiguratorProxy,
} from '../../helpers/contracts-getters';
import { insertContractAddressInDb } from '../../helpers/contracts-helpers';
import { ConfigNames, loadPoolConfig } from '../../helpers/configuration';

task('xave:sepolia-lendingpool-2-b', 'Deploy lending pool for prod enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');

    const addressesProvider = await getLendingPoolAddressesProvider();
    const poolConfig = loadPoolConfig(ConfigNames.XaveSepolia);
    const lendingPoolProxy = await getLendingPool(addressesProvider.address);
    const lendingPoolConfiguratorProxy = await getLendingPoolConfiguratorProxy(
      await addressesProvider.getLendingPoolConfigurator()
    );

    // Deploy deployment helper contracts
    console.log('deploying helper contracts ');
    const stableAndVariableTokensHelper = await deployStableAndVariableTokensHelper(
      [lendingPoolProxy.address, addressesProvider.address],
      verify
    );

    console.log('deploying stable and variable tokens helper');
    const aTokensAndRatesHelper = await deployATokensAndRatesHelper(
      [lendingPoolProxy.address, addressesProvider.address, lendingPoolConfiguratorProxy.address],
      verify
    );

    console.log('deploying aTokens and rates helper');
    await deployATokenImplementations(ConfigNames.XaveSepolia, poolConfig.ReservesConfig, verify);

    console.log('deploy aToken implementations');

    console.log(`
    StableAndVariableTokensHelper: ${stableAndVariableTokensHelper.address}
    aTokensAndRatesHelper: ${aTokensAndRatesHelper.address}
    `);
  });
