import { task } from 'hardhat/config';
import * as marketConfigs from '../../markets/halo';
import { HaloIncentives } from '../../markets/halo/incentivesEmission';
import { getRnbwIncentivesController } from '../../helpers/contracts-getters';
import { setDRE } from '../../helpers/misc-utils';

task('external:configure-incentives-emission', 'Initialize incentives controller').setAction(
  async ({ symbol }, localBRE) => {
    const network = localBRE.network.name;
    setDRE(localBRE);

    const rnbwIncentivesController = await getRnbwIncentivesController(
      marketConfigs.HaloConfig.IncentivesController[network]
    );

    await rnbwIncentivesController.configureAssets(HaloIncentives.EmissionConfig[network]);
  }
);
