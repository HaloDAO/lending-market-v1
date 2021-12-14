import { task } from 'hardhat/config';
import { eEthereumNetwork } from '../../../helpers/types';
import { getTreasuryAddress } from '../../../helpers/configuration';
import * as marketConfigs from '../../../markets/halo';
import * as reserveConfigs from '../../../markets/halo/reservesConfigs';
import { chooseATokenDeployment } from '../../../helpers/init-helpers';
import {
  getAaveOracle,
  getAToken,
  getLendingPool,
  getLendingPoolAddressesProvider,
  getLendingPoolConfiguratorImpl,
  getLendingPoolConfiguratorProxy,
  getMintableERC20,
  getRnbwIncentivesController,
  getUiPoolDataProvider,
} from '../../../helpers/contracts-getters';
import {
  deployDefaultReserveInterestRateStrategy,
  deployStableDebtToken,
  deployVariableDebtToken,
  deployRnbwIncentivesContoller,
} from '../../../helpers/contracts-deployments';
import { setDRE } from '../../../helpers/misc-utils';
import { ZERO_ADDRESS } from '../../../helpers/constants';
import { formatEther, parseEther } from '@ethersproject/units';
import { ethers } from 'ethers';
import { BUIDLEREVM_SUPPORTED_HARDFORKS } from '@nomiclabs/buidler/internal/constants';

task('external:lendingpool-action', 'Initialize incentives controller')
  .addParam('action', 'Pool action to call')
  .addParam('amount', 'Amount to use')
  .setAction(async ({ verify, symbol, action, amount }, localBRE) => {
    const network = localBRE.network.name;
    setDRE(localBRE);

    const DEPLOYER_ADDRESS = '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd';
    const TEST_ASSET = marketConfigs.HaloConfig.ReserveAssets[network].USDC;

    console.log(marketConfigs.HaloConfig.LendingPool[network]);
    const lendingPool = await getLendingPool(marketConfigs.HaloConfig.LendingPool[network]);
    const TEST_AMOUNT = parseEther(amount);

    switch (action) {
      case 'deposit':
        await lendingPool.deposit(TEST_ASSET, TEST_AMOUNT, DEPLOYER_ADDRESS, 0);
        break;
      case 'withdraw':
        await lendingPool.withdraw(TEST_ASSET, TEST_AMOUNT, DEPLOYER_ADDRESS);
        break;
      case 'borrow':
        await lendingPool.borrow(TEST_ASSET, TEST_AMOUNT, 2, 0, DEPLOYER_ADDRESS);
        break;
      case 'repay':
        await lendingPool.repay(TEST_ASSET, TEST_AMOUNT, 2, DEPLOYER_ADDRESS);
        break;
      case 'getUserReserveData':
        console.log(await lendingPool.getReserveData(TEST_ASSET));
        break;
      case 'getReservesList':
        console.log(await lendingPool.getReservesList());
        break;
      default:
        console.log('action not found');
        break;
    }

    //console.log(await lendingPool.getUserAccountData(DEPLOYER_ADDRESS));

    // address, amount, to, 0

    // console.log(await lendingPool.getReserveData(TEST_ASSET));

    //console.log();
    //
    //console.log(await lendingPoolOld.getReservesList());
  });
