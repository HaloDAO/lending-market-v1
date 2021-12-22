import { task } from 'hardhat/config';
import { eContractid } from '../../helpers/types';

task('halo:mainnet-6', 'Initialize lending pool configuration.')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify, pool }, localBRE) => {
    await localBRE.run('set-DRE');

    await localBRE.run(`deploy-${eContractid.UiHaloPoolDataProvider}`, { verify });

    await localBRE.run(`deploy-${eContractid.UiIncentiveDataProvider}`, { verify });
  });
