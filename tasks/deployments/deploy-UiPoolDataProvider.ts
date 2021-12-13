import { task } from 'hardhat/config';
import { eContractid, eEthereumNetwork, eNetwork, ePolygonNetwork } from '../../helpers/types';
import { deployUiPoolDataProvider } from '../../helpers/contracts-deployments';
import { exit } from 'process';
import { ethers } from 'ethers';

task(`deploy-${eContractid.UiPoolDataProvider}`, `Deploys the UiPoolDataProvider contract`)
  .addFlag('verify', 'Verify UiPoolDataProvider contract via Etherscan API.')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }
    const network = localBRE.network.name;

    const addressesByNetwork: {
      [key: string]: { incentivesController: string; aaveOracle: string };
    } = {
      [eEthereumNetwork.kovan]: {
        incentivesController: '0x8Bfa7b45Ad86df7BeD67E91A676b7495B0402d04',
        aaveOracle: '0x28408A6fCb70268f3CD7a3af384942DD596fAe27',
      }, // TODO: Change
      [eEthereumNetwork.main]: {
        incentivesController: '0x8Bfa7b45Ad86df7BeD67E91A676b7495B0402d04',
        aaveOracle: '0xa50ba011c48153de246e5192c8f9258a2ba79ca9',
      },
      [ePolygonNetwork.matic]: {
        incentivesController: '0x357D51124f59836DeD84c8a1730D72B749d8BC23',
        aaveOracle: '0x21451bD7b528896B4AB2b9764b521D6ed641708d',
      },
      [ePolygonNetwork.mumbai]: {
        incentivesController: '0xd41aE58e803Edf4304334acCE4DC4Ec34a63C644',
        aaveOracle: '0xC365C653f7229894F93994CD0b30947Ab69Ff1D5',
      },
    };
    const supportedNetworks = Object.keys(addressesByNetwork);

    if (!supportedNetworks.includes(network)) {
      console.error(`[task][error] Network "${network}" not supported, please use one of: ${supportedNetworks.join()}`);
      exit(2);
    }

    const oracle = addressesByNetwork[network].aaveOracle;
    const incentivesController = addressesByNetwork[network].incentivesController;

    console.log(`\n- UiPoolDataProvider deployment`);

    const uiPoolDataProvider = await deployUiPoolDataProvider([incentivesController, oracle], verify);

    console.log('UiPoolDataProvider deployed at:', uiPoolDataProvider.address);
    console.log(`\tFinished UiPoolDataProvider deployment`);
  });
