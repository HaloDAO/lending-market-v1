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

task('halo:dev:initialize-lending-pool', 'Initialize lending pool configuration.')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .addParam('pool', `Pool name to retrieve configuration, supported: ${Object.values(ConfigNames)}`)
  .setAction(async ({ verify, pool }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = <eNetwork>localBRE.network.name;
    const signer = await getFirstSigner();
    const poolConfig = loadPoolConfig(pool);

    const { ATokenNamePrefix, StableDebtTokenNamePrefix, VariableDebtTokenNamePrefix, SymbolPrefix, WethGateway } =
      poolConfig;
    const mockTokens = await getAllHaloMockedTokens();
    const allTokenAddresses = getAllTokenAddresses(mockTokens);
    //console.log('mock tokens');
    //console.log(mockTokens);

    const addressesProvider = await getLendingPoolAddressesProvider();

    const protoPoolReservesAddresses = <{ [symbol: string]: tEthereumAddress }>(
      filterMapBy(allTokenAddresses, (key: string) => !key.includes('UNI_'))
    );

    const testHelpers = await deployAaveProtocolDataProvider(addressesProvider.address, verify);

    const reservesParams = getReservesConfigByPool(AavePools.halo);

    const admin = await addressesProvider.getPoolAdmin();

    //const treasuryAddress = await getTreasuryAddress(poolConfig);
    const lendingPoolAddress = await addressesProvider.getLendingPool();
    const rewardToken = await deployVestingContractMock([allTokenAddresses['RNBW']], false);
    const curveFactory = await deployCurveFactoryMock([allTokenAddresses['USDC'], [], []], false);

    // TODO: Make dynamic, for local only. For Kovan, add another const file
    const HALO_CONTRACT_ADDRESSES = {
      rewardToken: rewardToken.address, //xrnbw
      emissionManager: await signer.getAddress(), // deployer first?
      lendingPoolAddress: lendingPoolAddress,
      rnbw: allTokenAddresses['RNBW'],
      xrnbw: rewardToken.address,
      curveFactory: curveFactory.address,
      usdc: allTokenAddresses['USDC'],
      usdcRnbwPair: ZERO_ADDRESS, //mock
    };

    // HALO Treasury contract
    const treasury = await deployTreasury(
      [
        lendingPoolAddress,
        HALO_CONTRACT_ADDRESSES.rnbw,
        HALO_CONTRACT_ADDRESSES.xrnbw,
        HALO_CONTRACT_ADDRESSES.curveFactory,
        HALO_CONTRACT_ADDRESSES.usdc,
        HALO_CONTRACT_ADDRESSES.usdcRnbwPair,
      ],
      false
    );

    // HALO Incentives Controller contract
    const incentiveController = await deployRnbwIncentivesContoller(
      [HALO_CONTRACT_ADDRESSES.rewardToken, HALO_CONTRACT_ADDRESSES.emissionManager, '10000'],
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
    }
    await authorizeWETHGateway(gateway, lendingPoolAddress);
  });
