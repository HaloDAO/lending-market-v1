import { task } from 'hardhat/config';
import { generateMarketConfigJSON } from '../../helpers/foundry-helpers';
import { ConfigNames } from '../../helpers/configuration';
import { eAvalancheNetwork } from '../../helpers/types';

task('xave:avax-deployment-config', 'Export used config').setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');

  const tokens: string[] = ['USDC', 'EURC', 'VCHF', 'VEUR', 'LP-EURC-USDC', 'LP-VEUR-USDC', 'LP-VCHF-USDC'];
  // const tokens: string[] = ['USDC'];

  await generateMarketConfigJSON(tokens, ConfigNames.XaveAvalanche, eAvalancheNetwork.avalanche);
});
