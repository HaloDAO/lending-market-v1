import { task } from 'hardhat/config';
import { eAvalancheNetwork, eContractid, eEthereumNetwork, eNetwork, ePolygonNetwork } from '../../../helpers/types';

import {
  getHaloUiPoolDataProvider,
  getIncentivePoolDataProvider,
  getUiPoolDataProvider,
  getWETHMocked,
} from '../../../helpers/contracts-getters';
import { parseEther } from 'ethers/lib/utils';

task(`external:uipoolprovider-checker`, `Check UI Pool Provider`).setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');
  if (!localBRE.network.config.chainId) {
    throw new Error('INVALID_CHAIN_ID');
  }
  const network = localBRE.network.name;

  const uiPoolDataProvider = await getHaloUiPoolDataProvider('0xbca5c841eC9cC6Bd54ee18450eAe3B4D7b68146b');
  const uiIncentivesDataProvider = await getIncentivePoolDataProvider('0x22fA9599D8007B279BB935718DeE408fCad9Ea0B');

  console.log(await uiPoolDataProvider.getReservesData('0x8eBFB2FC668a0ccCC8ADa5133c721a34060D1cDe'));
});
