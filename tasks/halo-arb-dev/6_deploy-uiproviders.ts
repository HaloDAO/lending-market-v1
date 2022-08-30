import { task } from 'hardhat/config';
import { eContractid } from '../../helpers/types';

task('halo:arb-dev-dataproviders-6', 'Initialize Data Providers')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');

    await localBRE.run(`deploy-${eContractid.UiHaloPoolDataProvider}`, { verify });

    await localBRE.run(`deploy-${eContractid.UiIncentiveDataProvider}`, { verify });
  });
