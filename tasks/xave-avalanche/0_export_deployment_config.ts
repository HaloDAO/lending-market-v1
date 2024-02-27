import { task } from 'hardhat/config';
import { generateMarketConfigJSON } from '../../helpers/foundry-helpers';
import { ConfigNames } from '../../helpers/configuration';
import { eAvalancheNetwork, eEthereumNetwork } from '../../helpers/types';

task('xave:avax-deployment-config', 'Export used config').setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');

  const tokens: string[] = ['USDC', 'EUROC', 'VCHF', 'VEUR', 'LP_EUROC_USDC', 'LP_VEUR_USDC', 'LP_VCHF_USDC'];

  await generateMarketConfigJSON(tokens, ConfigNames.XaveAvalanche, eAvalancheNetwork.avalanche);
});
