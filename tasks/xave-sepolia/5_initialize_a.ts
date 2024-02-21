import { task } from 'hardhat/config';
import {
  deployLendingPoolCollateralManager,
  // deployMockFlashLoanReceiver,
  deployWalletBalancerProvider,
  deployAaveProtocolDataProvider,
  authorizeWETHGateway,
  // deployTreasury,
  deployRnbwIncentivesContoller,
} from '../../helpers/contracts-deployments-ledger';
import { getParamPerNetwork } from '../../helpers/contracts-helpers';
import { eNetwork } from '../../helpers/types';
import { ConfigNames, loadPoolConfig } from '../../helpers/configuration';
import { eContractid } from '../../helpers/types';
import { waitForTx, notFalsyOrZeroAddress } from '../../helpers/misc-utils';
import { configureReservesByHelper, initReservesByHelper } from '../../helpers/init-helpers';
import {
  getAaveProtocolDataProvider,
  getLendingPoolAddressesProvider,
  getWETHGateway,
} from '../../helpers/contracts-getters';
import { insertContractAddressInDb } from '../../helpers/contracts-helpers';
import { ZERO_ADDRESS } from '../../helpers/constants';
// import { HALO_CONTRACT_ADDRESSES } from '../../markets/halo-matic/constants';

task('xave:sepolia-initialize-5-a', 'Initialize lending pool configuration.')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = <eNetwork>localBRE.network.name;

    const addressesProvider = await getLendingPoolAddressesProvider();

    console.log('deploying aave protocol data provider');
    const testHelpers = await deployAaveProtocolDataProvider(addressesProvider.address, verify);
    await insertContractAddressInDb(eContractid.AaveProtocolDataProvider, testHelpers.address);

    // Deploy Halo Contracts
    // HALO Treasury contract
    // const treasury = await deployTreasury(
    //   [
    //     lendingPoolAddress,
    //     HALO_CONTRACT_ADDRESSES[network].rnbw,
    //     HALO_CONTRACT_ADDRESSES[network].xrnbw,
    //     HALO_CONTRACT_ADDRESSES[network].curveFactory,
    //     HALO_CONTRACT_ADDRESSES[network].usdc,
    //     HALO_CONTRACT_ADDRESSES[network].usdcRnbwPair,
    //   ],
    //   false
    // );

    // HALO Incentives Controller contract
    // Distribution end set to 100 years
    console.log('deploying incentive controller');
    const incentiveController = ZERO_ADDRESS;

    console.log(`
    AaveProtocolDataProvider: ${testHelpers.address}
  
    `);

    /* Halo IncentivesController:  ${incentiveController.address} */
  });
