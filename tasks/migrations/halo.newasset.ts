import { task } from 'hardhat/config';
import { checkVerification } from '../../helpers/etherscan-verification';
import { ConfigNames } from '../../helpers/configuration';
import { printContracts } from '../../helpers/misc-utils';
import { getEthersSigners } from '../../helpers/contracts-helpers';

task('halo:new-asset', 'Deploy development enviroment')
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('verify', 'Verify contracts at Etherscan')
  .addFlag('lp', 'If asset is an LP')
  .setAction(async ({ symbol, verify, lp }, localBRE) => {
    // To be used in full kovan deployment also
    await localBRE.run('set-DRE');

    // Prevent loss of gas verifying all the needed ENVs for Etherscan verification
    if (verify) {
      checkVerification();
    }
    console.log('Adding new asset process started\n');

    console.log('1. Deploy lending market implementation tokens and initialize reserve');
    await localBRE.run('halo:newasset:initialize-reserve', { verify, symbol: symbol, lp });

    console.log('2. Configure reserve');
    await localBRE.run('halo:newasset:configure-reserve', { verify, symbol: symbol });

    console.log('\nFinished adding asset!');
  });
