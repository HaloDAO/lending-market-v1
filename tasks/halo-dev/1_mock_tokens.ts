import { task } from 'hardhat/config';
import { deployAllHaloMockTokens } from '../../helpers/contracts-deployments';

task('halo:dev:deploy-mock-tokens', 'Deploy mock tokens for dev enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    await deployAllHaloMockTokens(verify);
  });
