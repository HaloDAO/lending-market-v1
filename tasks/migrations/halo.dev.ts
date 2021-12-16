import { task } from 'hardhat/config';
import { checkVerification } from '../../helpers/etherscan-verification';
import { ConfigNames } from '../../helpers/configuration';
import { printContracts } from '../../helpers/misc-utils';
import { getEthersSigners } from '../../helpers/contracts-helpers';

task('halo:dev', 'Deploy development enviroment')
  .addParam('withmocktokens', 'deploy additional mock tokens')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ withmocktokens, verify }, localBRE) => {
    const POOL_NAME = ConfigNames.Halo;

    // To be used in full kovan deployment also
    await localBRE.run('set-DRE');

    // Prevent loss of gas verifying all the needed ENVs for Etherscan verification
    if (verify) {
      checkVerification();
    }

    console.log('Migration started\n');

    if (withmocktokens == true) {
      console.log('0. Deploy mock tokens');
      await localBRE.run('halo:dev:deploy-mock-tokens', { verify });
    }

    console.log('1. Deploy address provider');
    await localBRE.run('halo:dev:deploy-address-provider', { verify });

    console.log('Done deploying address provider');

    console.log('2. Deploy lending pool');
    await localBRE.run('halo:dev:deploy-lending-pool', { verify });

    console.log('3. Deploy oracles');
    await localBRE.run('halo:dev:deploy-oracles', { verify, pool: POOL_NAME });

    console.log('4. Deploy WETH Gateway');
    await localBRE.run('full-deploy-weth-gateway', { verify, pool: POOL_NAME });

    console.log('5. Initialize lending pool');
    await localBRE.run('halo:dev:initialize-lending-pool', { verify, pool: POOL_NAME });

    console.log('\nFinished migration');
    printContracts();
  });
