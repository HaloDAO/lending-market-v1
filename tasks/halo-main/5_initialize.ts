import { task } from 'hardhat/config';
import {
  deployLendingPoolCollateralManager,
  deployMockFlashLoanReceiver,
  deployWalletBalancerProvider,
  deployAaveProtocolDataProvider,
  authorizeWETHGateway,
  deployTreasury,
  deployRnbwIncentivesContoller,
} from '../../helpers/contracts-deployments';
import { getParamPerNetwork } from '../../helpers/contracts-helpers';
import { eNetwork } from '../../helpers/types';
import { ConfigNames, getReservesConfigByPool, loadPoolConfig } from '../../helpers/configuration';
import { tEthereumAddress, AavePools, eContractid } from '../../helpers/types';
import { waitForTx, filterMapBy, notFalsyOrZeroAddress, printContracts } from '../../helpers/misc-utils';
import { configureReservesByHelper, initReservesByHelper } from '../../helpers/init-helpers';
import { getAllTokenAddresses } from '../../helpers/mock-helpers';
import {
  getAllHaloMockedTokens,
  getLendingPoolAddressesProvider,
  getWETHGateway,
} from '../../helpers/contracts-getters';
import { insertContractAddressInDb } from '../../helpers/contracts-helpers';
import { HALO_CONTRACT_ADDRESSES } from '../../markets/halo/constants';

task('halo:mainnet-5', 'Initialize lending pool configuration.')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = <eNetwork>localBRE.network.name;

    const poolConfig = loadPoolConfig(ConfigNames.Halo);
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

    const testHelpers = await deployAaveProtocolDataProvider(addressesProvider.address, verify);
    const admin = await addressesProvider.getPoolAdmin();
    const lendingPoolAddress = await addressesProvider.getLendingPool();
    const reserveAssets = await getParamPerNetwork(ReserveAssets, network);

    // Deploy Halo Contracts
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
    // Distribution end set to 100 years
    const incentiveController = await deployRnbwIncentivesContoller(
      [HALO_CONTRACT_ADDRESSES[network].rewardToken, HALO_CONTRACT_ADDRESSES[network].emissionManager, '3153600000'],
      false
    );

    // Initialize and Configure Reserves, Atokens, Debt Tokens
    await initReservesByHelper(
      ReservesConfig,
      reserveAssets,
      ATokenNamePrefix,
      StableDebtTokenNamePrefix,
      VariableDebtTokenNamePrefix,
      SymbolPrefix,
      admin,
      treasury.address,
      incentiveController.address,
      ConfigNames.Halo,
      verify
    );

    await configureReservesByHelper(ReservesConfig, reserveAssets, testHelpers, admin);

    const collateralManager = await deployLendingPoolCollateralManager(verify);
    await waitForTx(await addressesProvider.setLendingPoolCollateralManager(collateralManager.address));

    // TODO: Check but skip first
    // const mockFlashLoanReceiver = await deployMockFlashLoanReceiver(addressesProvider.address, verify);
    // await insertContractAddressInDb(eContractid.MockFlashLoanReceiver, mockFlashLoanReceiver.address);

    const walletBalanceProvider = await deployWalletBalancerProvider(verify);
    await insertContractAddressInDb(eContractid.AaveProtocolDataProvider, testHelpers.address);

    let gateway = getParamPerNetwork(WethGateway, network);

    if (!notFalsyOrZeroAddress(gateway)) {
      gateway = (await getWETHGateway()).address;
      await authorizeWETHGateway(gateway, lendingPoolAddress);
    }

    console.log(`
    AaveProtocolDataProvider: ${testHelpers.address}
    Halo Treasury: ${treasury.address}
    Halo IncentivesController: ${incentiveController.address}
    WalletBalanceProvider: ${walletBalanceProvider.address}
    `);
  });
