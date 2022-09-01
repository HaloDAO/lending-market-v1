import { task } from 'hardhat/config';
import {
  deployLendingPoolCollateralManager,
  // deployMockFlashLoanReceiver,
  deployWalletBalancerProvider,
  authorizeWETHGateway,
} from '../../helpers/contracts-deployments';
import { getParamPerNetwork } from '../../helpers/contracts-helpers';
import { eNetwork } from '../../helpers/types';
import { ConfigNames, loadPoolConfig } from '../../helpers/configuration';

import { waitForTx } from '../../helpers/misc-utils';
import { configureReservesByHelper, initReservesByHelper } from '../../helpers/init-helpers';
import {
  getAaveProtocolDataProvider,
  getLendingPoolAddressesProvider,
  getRnbwIncentivesController,
} from '../../helpers/contracts-getters';

import { HALO_CONTRACT_ADDRESSES } from '../../markets/halo-matic/constants';
import { AaveProtocolDataProvider } from '../../types';

task('halo:matic-initialize-5-b', 'Initialize lending pool configuration.')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = <eNetwork>localBRE.network.name;

    const poolConfig = loadPoolConfig(ConfigNames.HaloMatic);
    const {
      ATokenNamePrefix,
      StableDebtTokenNamePrefix,
      VariableDebtTokenNamePrefix,
      SymbolPrefix,
      WethGateway,
      ReserveAssets,
      ReservesConfig,
    } = poolConfig;

    const addressesProvider = await getLendingPoolAddressesProvider();
    const testHelpers: AaveProtocolDataProvider = await getAaveProtocolDataProvider();
    const admin = await addressesProvider.getPoolAdmin();
    const lendingPoolAddress = await addressesProvider.getLendingPool();
    const reserveAssets = await getParamPerNetwork(ReserveAssets, network);
    const incentiveController = await getRnbwIncentivesController();
    const treasury = HALO_CONTRACT_ADDRESSES.matic.treasury;

    console.log('initializing reserves..');
    // Initialize and Configure Reserves, Atokens, Debt Tokens
    await initReservesByHelper(
      ReservesConfig,
      reserveAssets,
      ATokenNamePrefix,
      StableDebtTokenNamePrefix,
      VariableDebtTokenNamePrefix,
      SymbolPrefix,
      admin,
      treasury,
      incentiveController.address,
      ConfigNames.HaloMatic,
      verify
    );

    console.log('configuring reserves..');
    await configureReservesByHelper(ReservesConfig, reserveAssets, testHelpers, admin);

    console.log('deploying collateral manager');
    const collateralManager = await deployLendingPoolCollateralManager(verify);
    console.log('setting lending pool collateral proxy');
    await waitForTx(await addressesProvider.setLendingPoolCollateralManager(collateralManager.address));

    // TODO: Check but skip first
    // const mockFlashLoanReceiver = await deployMockFlashLoanReceiver(addressesProvider.address, verify);
    // await insertContractAddressInDb(eContractid.MockFlashLoanReceiver, mockFlashLoanReceiver.address);
    console.log('deploying wallet balance provider');
    const walletBalanceProvider = await deployWalletBalancerProvider(verify);
    console.log('wallet balance provider deployed');

    let gateway = getParamPerNetwork(WethGateway, network);

    console.log('authorizing WETH gateway');
    await authorizeWETHGateway(gateway, lendingPoolAddress);
    console.log('WETH Gateway Authorized');

    console.log(`
    WalletBalanceProvider: ${walletBalanceProvider.address}
    `);
  });
