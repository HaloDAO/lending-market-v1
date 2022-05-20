import { task } from 'hardhat/config';
import { checkVerification } from '../../helpers/etherscan-verification';
import { ConfigNames } from '../../helpers/configuration';
import { printContracts } from '../../helpers/misc-utils';
import { getEthersSigners } from '../../helpers/contracts-helpers';

task('halo-arb:dev', 'Deploy development enviroment')
  .addParam('withmocktokens', 'deploy additional mock tokens')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ withmocktokens, verify }, localBRE) => {
    const POOL_NAME = ConfigNames.HaloArb;

    // To be used in full kovan deployment also
    await localBRE.run('set-DRE');

    // Prevent loss of gas verifying all the needed ENVs for Etherscan verification
    if (verify) {
      checkVerification();
    }

    console.log('Migration started\n');

    if (withmocktokens === 'true') {
      console.log('0. Deploy mock tokens');
      await localBRE.run('halo:arb-dev:deploy-mock-tokens', { verify });
    }

    console.log('1. Deploy address provider');
    await localBRE.run('halo:arb-dev-addressproviders-1', { verify });

    console.log('Done deploying address provider');

    console.log('2. Deploy lending pool');
    await localBRE.run('halo:arb-dev-lendingpool-2', { verify, pool: POOL_NAME });

    console.log('3. Deploy oracles');
    await localBRE.run('halo:arb-dev:deploy-oracles', { verify, pool: POOL_NAME });

    console.log('4. Deploy WETH Gateway');
    await localBRE.run('halo:arb-dev-wethgateway-4', { verify, pool: POOL_NAME });

    console.log('5. Initialize lending pool');
    await localBRE.run('halo:arb-dev-initialize-5', { verify, pool: POOL_NAME });

    console.log('6. Deploy UI Providers');
    await localBRE.run('halo:arb-dev-dataproviders-6', { verify });

    console.log('\nFinished migration');
    printContracts();
  });
