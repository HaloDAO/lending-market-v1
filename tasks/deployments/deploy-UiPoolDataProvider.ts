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
        incentivesController: '0x0B5a00a5F8Be5FDf1e3F3bc341b485cC7fBCF50e',
        aaveOracle: '0x71D8B7bf8491F1DE76604eA99A390c44E46dF53E',
      }, // TODO: Change
      [eEthereumNetwork.main]: {
        incentivesController: '0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5',
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
    const incentivesController = addressesByNetwork[network].aaveOracle;

    console.log(`\n- UiPoolDataProvider deployment`);

    // const uiPoolDataProvider = await deployUiPoolDataProvider([incentivesController, oracle], verify);
    const uiPoolDataProvider = await deployUiPoolDataProvider([ethers.constants.AddressZero, oracle], verify);

    console.log('UiPoolDataProvider deployed at:', uiPoolDataProvider.address);
    console.log(`\tFinished UiPoolDataProvider deployment`);
  });
