import { task } from 'hardhat/config';
import { eAvalancheNetwork, eContractid, eEthereumNetwork, eNetwork, ePolygonNetwork } from '../../helpers/types';
import { deployUiIncentiveDataProvider, deployUiPoolDataProvider } from '../../helpers/contracts-deployments';
import { exit } from 'process';
import { ethers } from 'ethers';
import { HaloIncentives } from '../../markets/halo/incentivesEmission';
import HaloConfig from '../../markets/halo';

task(`deploy-${eContractid.UiIncentiveDataProvider}`, `Deploys the UiPoolDataProvider contract`)
  .addFlag('verify', 'Verify UiPoolDataProvider contract via Etherscan API.')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }

    console.log(`\n- UiIncentivesDataProvider deployment`);

    const uiIncentivesDataProvider = await deployUiIncentiveDataProvider(verify);

    console.log('UiIncentivesDataProvider deployed at:', uiIncentivesDataProvider.address);
    console.log(`\tFinished UiIncentivesDataProvider deployment`);
  });
