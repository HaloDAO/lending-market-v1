import { task } from 'hardhat/config';
import {
  deployLendingPoolCollateralManager,
  deployMockFlashLoanReceiver,
  deployWalletBalancerProvider,
  deployAaveProtocolDataProvider,
  authorizeWETHGateway,
  deployTreasury,
  deployRnbwIncentivesContoller,
  deployVestingContractMock,
  deployCurveFactoryMock,
} from '../../helpers/contracts-deployments';
import { getParamPerNetwork } from '../../helpers/contracts-helpers';
import { eNetwork } from '../../helpers/types';
import { ConfigNames, getReservesConfigByPool, getTreasuryAddress, loadPoolConfig } from '../../helpers/configuration';

import { tEthereumAddress, AavePools, eContractid } from '../../helpers/types';
import { waitForTx, filterMapBy, notFalsyOrZeroAddress } from '../../helpers/misc-utils';
import { configureReservesByHelper, initReservesByHelper } from '../../helpers/init-helpers';
import { getAllTokenAddresses } from '../../helpers/mock-helpers';
import { ZERO_ADDRESS } from '../../helpers/constants';
import {
  getAllHaloMockedTokens,
  getCurveFactoryMock,
  getFirstSigner,
  getLendingPoolAddressesProvider,
  getVestingContract,
  getWETHGateway,
} from '../../helpers/contracts-getters';
import { insertContractAddressInDb } from '../../helpers/contracts-helpers';
import { HALO_CONTRACT_ADDRESSES } from '../../markets/halo/constants';

task('halo:dev:initialize-lending-pool', 'Initialize lending pool configuration.')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .addParam('pool', `Pool name to retrieve configuration, supported: ${Object.values(ConfigNames)}`)
  .setAction(async ({ verify, pool }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = <eNetwork>localBRE.network.name;

    const poolConfig = loadPoolConfig(pool);
    const { ATokenNamePrefix, StableDebtTokenNamePrefix, VariableDebtTokenNamePrefix, SymbolPrefix, WethGateway } =
      poolConfig;
    const mockTokens = await getAllHaloMockedTokens();
    const allTokenAddresses = getAllTokenAddresses(mockTokens);

    const addressesProvider = await getLendingPoolAddressesProvider();

    const protoPoolReservesAddresses = <{ [symbol: string]: tEthereumAddress }>(
      filterMapBy(allTokenAddresses, (key: string) => !key.includes('UNI_'))
    );

    const testHelpers = await deployAaveProtocolDataProvider(addressesProvider.address, verify);
    const reservesParams = getReservesConfigByPool(AavePools.halo);
    const admin = await addressesProvider.getPoolAdmin();

    //const treasuryAddress = await getTreasuryAddress(poolConfig);
    const lendingPoolAddress = await addressesProvider.getLendingPool();

    // HALO Treasury contract
    const treasury = await deployTreasury(
      [
        lendingPoolAddress,
        HALO_CONTRACT_ADDRESSES[network].rnbw,
        HALO_CONTRACT_ADDRESSES[network].xrnbw,
        HALO_CONTRACT_ADDRESSES[network].curveFactory,
        HALO_CONTRACT_ADDRESSES[network].usdc,
        HALO_CONTRACT_ADDRESSES[network].usdcRnbwPair,
      ],
      false
    );

    // HALO Incentives Controller contract
    // TODO: Check emission per second
    const incentiveController = await deployRnbwIncentivesContoller(
      [HALO_CONTRACT_ADDRESSES[network].rewardToken, HALO_CONTRACT_ADDRESSES[network].emissionManager, '10000'],
      false
    );

    await initReservesByHelper(
      reservesParams,
      protoPoolReservesAddresses,
      ATokenNamePrefix,
      StableDebtTokenNamePrefix,
      VariableDebtTokenNamePrefix,
      SymbolPrefix,
      admin,
      treasury.address,
      incentiveController.address,
      pool,
      verify
    );

    await configureReservesByHelper(reservesParams, protoPoolReservesAddresses, testHelpers, admin);

    const collateralManager = await deployLendingPoolCollateralManager(verify);
    await waitForTx(await addressesProvider.setLendingPoolCollateralManager(collateralManager.address));

    const mockFlashLoanReceiver = await deployMockFlashLoanReceiver(addressesProvider.address, verify);
    await insertContractAddressInDb(eContractid.MockFlashLoanReceiver, mockFlashLoanReceiver.address);

    await deployWalletBalancerProvider(verify);

    await insertContractAddressInDb(eContractid.AaveProtocolDataProvider, testHelpers.address);

    let gateway = getParamPerNetwork(WethGateway, network);

    if (!notFalsyOrZeroAddress(gateway)) {
      gateway = (await getWETHGateway()).address;
      await authorizeWETHGateway(gateway, lendingPoolAddress);
    }
  });
