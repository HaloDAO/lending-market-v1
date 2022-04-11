import { task } from 'hardhat/config';
import { deployAllHaloMockTokens } from '../../helpers/contracts-deployments';
import { getFirstSigner } from '../../helpers/contracts-getters';

task('halo:arb-addressproviders-1 --network arbitrumRinkeby', 'Deploy mock tokens for dev enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    const signer = await getFirstSigner();

    // console.log(await signer.getAddress());
    await deployAllHaloMockTokens(verify);
  });
