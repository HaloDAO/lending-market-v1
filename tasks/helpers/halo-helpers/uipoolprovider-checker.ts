import { task } from 'hardhat/config';
import { eAvalancheNetwork, eContractid, eEthereumNetwork, eNetwork, ePolygonNetwork } from '../../../helpers/types';
import {
  getHaloUiPoolDataProvider,
  getIncentivePoolDataProvider,
  getUiPoolDataProvider,
  getWETHMocked,
} from '../../../helpers/contracts-getters';
import { parseEther } from 'ethers/lib/utils';
import { parse } from 'path';

task(`external:uipoolprovider-checker`, `Check UI Pool Provider`).setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');
  if (!localBRE.network.config.chainId) {
    throw new Error('INVALID_CHAIN_ID');
  }
  const network = localBRE.network.name;

  const uiPoolDataProvider = await getHaloUiPoolDataProvider('0xC54Ad1ff797189239333Ba7dC616A9534ee03e8D');
  // const uiIncentivesDataProvider = await getIncentivePoolDataProvider('0x22fA9599D8007B279BB935718DeE408fCad9Ea0B');

  console.log(await uiPoolDataProvider.getReservesList('0xD8708572AfaDccE523a8B8883a9b882a79cbC6f2'));
});
