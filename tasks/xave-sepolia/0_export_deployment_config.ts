import { task } from 'hardhat/config';
import { generateMarketConfigJSON } from '../../helpers/foundry-helpers';
import { ConfigNames } from '../../helpers/configuration';
import { eEthereumNetwork } from '../../helpers/types';

task('xave:sepolia-deployment-config', 'Export used config').setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');

  const tokens: string[] = ['USDC', 'XSGD', 'LP_XSGD_USDC'];

  await generateMarketConfigJSON(tokens, ConfigNames.XaveSepolia, eEthereumNetwork.sepolia);
});
