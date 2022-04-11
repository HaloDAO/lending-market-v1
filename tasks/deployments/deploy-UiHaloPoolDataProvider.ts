import { task } from 'hardhat/config';
import {
  eAvalancheNetwork,
  eContractid,
  eEthereumNetwork,
  eNetwork,
  ePolygonNetwork,
  eArbitrumNetwork,
} from '../../helpers/types';
import { deployHaloUiPoolDataProvider, deployUiPoolDataProvider } from '../../helpers/contracts-deployments';
import { exit } from 'process';
import { ethers } from 'ethers';
import { HaloIncentives } from '../../markets/halo/incentivesEmission';
import HaloConfig from '../../markets/halo';

task(`deploy-${eContractid.UiHaloPoolDataProvider}`, `Deploys the UiHaloPoolDataProvider contract`)
  .addFlag('verify', 'Verify UiPoolDataProvider contract via Etherscan API.')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }
    const network = localBRE.network.name;

    // Chainlink Oracles
    const addressesByNetwork: {
      [key: string]: { ethUsdOracle: string };
    } = {
      [eEthereumNetwork.kovan]: {
        ethUsdOracle: '0x9326BFA02ADD2366b30bacB125260Af641031331',
      },
      [eEthereumNetwork.main]: {
        ethUsdOracle: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419',
      },
      //@todo: replace with actual ETH/USD oracle for Arbitrum network
      [eArbitrumNetwork.arbitrumRinkeby]: {
        ethUsdOracle: '	0x6eFd3CCf5c673bd5A7Ea91b414d0307a5bAb9cC1',
      },
    };
    const supportedNetworks = Object.keys(addressesByNetwork);

    if (!supportedNetworks.includes(network)) {
      console.error(`[task][error] Network "${network}" not supported, please use one of: ${supportedNetworks.join()}`);
      exit(2);
    }

    console.log(`\n- UiHaloPoolDataProvider deployment`);

    const ETHUSD_ChainlinkAggregator = addressesByNetwork[network].ethUsdOracle;

    const uiPoolDataProvider = await deployHaloUiPoolDataProvider(
      [ETHUSD_ChainlinkAggregator, ETHUSD_ChainlinkAggregator],
      verify
    );

    console.log('UiPoolDataProvider deployed at:', uiPoolDataProvider.address);
    console.log(`\tFinished UiPoolDataProvider deployment`);
  });
