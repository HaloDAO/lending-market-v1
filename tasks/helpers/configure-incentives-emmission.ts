import { task } from 'hardhat/config';
import { eEthereumNetwork } from '../../helpers/types';
import { getTreasuryAddress } from '../../helpers/configuration';
import * as marketConfigs from '../../markets/halo';
import * as reserveConfigs from '../../markets/halo/reservesConfigs';
import { chooseATokenDeployment } from '../../helpers/init-helpers';
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
} from '../../helpers/contracts-getters';
import {
  deployDefaultReserveInterestRateStrategy,
  deployStableDebtToken,
  deployVariableDebtToken,
  deployRnbwIncentivesContoller,
} from '../../helpers/contracts-deployments';
import { setDRE } from '../../helpers/misc-utils';
import { ZERO_ADDRESS } from '../../helpers/constants';
import { formatEther, parseEther } from '@ethersproject/units';
import { ethers } from 'ethers';

const ATOKEN_ADDRESS = {
  aDai: '0x1dd0911932704cA3b4815840Db6713f91905B612',
  aUSDT: '0x93d11302bf26E4eFf5F76c15FFB2eA94326Bc1C8',
  aUSDC: '0x9d643d9632af2eCc20B151C2d354bB38A534a08B',
};

const EMISSION_CONFIG = [
  {
    emissionPerSecond: parseEther('1'),
    totalStaked: 0,
    underlyingAsset: ATOKEN_ADDRESS.aDai,
  },
  {
    emissionPerSecond: parseEther('2'),
    totalStaked: 0,
    underlyingAsset: ATOKEN_ADDRESS.aUSDC,
  },
];

const LENDING_POOL_ADDRESS_PROVIDER = {
  //main: '0xb53c1a33016b2dc2ff3653530bff1848a515c8c5', // TODO: Change
  kovan: '0xBcD2560E79B4Aa5c3A73A56Fd556e88e61B0e18F',
};

const isSymbolValid = (symbol: string, network: eEthereumNetwork) =>
  Object.keys(reserveConfigs).includes('strategy' + symbol) &&
  marketConfigs.HaloConfig.ReserveAssets[network][symbol] &&
  marketConfigs.HaloConfig.ReservesConfig[symbol] === reserveConfigs['strategy' + symbol];

task('external:configure-incentives-emission', 'Initialize incentives controller').setAction(
  async ({ verify, symbol }, localBRE) => {
    const network = localBRE.network.name;

    const DEPLOYER_ADDRESS = '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd';
    /*
    if (!isSymbolValid(symbol, network as eEthereumNetwork)) {
      throw new Error(
        `
WRONG RESERVE ASSET SETUP:
        The symbol ${symbol} has no reserve Config and/or reserve Asset setup.
        update /markets/halo/index.ts and add the asset address for ${network} network
        update /markets/halo/reservesConfigs.ts and add parameters for ${symbol}
        `
      );
   
    }

    */
    setDRE(localBRE);

    const addressProvider = await getLendingPoolAddressesProvider(LENDING_POOL_ADDRESS_PROVIDER[network]); // TODO: Change this
    const poolAddress = await addressProvider.getLendingPool();
    const lendingPool = await getLendingPool(poolAddress);

    //console.log(await lendingPool.getReservesList());
    //const treasuryAddress = await getTreasuryAddress(marketConfigs.HaloConfig);

    const rnbwIncentivesController = await getRnbwIncentivesController(''); // TODO: Change this

    await rnbwIncentivesController.configureAssets([
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: '0x93d11302bf26E4eFf5F76c15FFB2eA94326Bc1C8', // TODO: Change this, aTokenAddress
      },
      {
        emissionPerSecond: parseEther('2.2'),
        totalStaked: 0,
        underlyingAsset: '0x9d643d9632af2eCc20B151C2d354bB38A534a08B', // TODO: Change this,  aTokenAddress
      },
    ]);

    const assetDataUSDT = await rnbwIncentivesController.assets('0x93d11302bf26E4eFf5F76c15FFB2eA94326Bc1C8');

    console.log(assetDataUSDT);
    const assetDataUSDC = await rnbwIncentivesController.assets('0x9d643d9632af2eCc20B151C2d354bB38A534a08B');

    console.log(assetDataUSDC);
    console.log(await rnbwIncentivesController.getUserUnclaimedRewards('0x235A2ac113014F9dcb8aBA6577F20290832dDEFd'));

    console.log('migrate incentives controlelr');

    /*
    const uiPool = await getUiPoolDataProvider('0x97C1349D303d0B43Fcc6742f75D6465E2139f052');
    console.log(await uiPool.getReservesData(ethers.constants.AddressZero, DEPLOYER_ADDRESS));

    //console.log(await lendingPool.getUserConfiguration(DEPLOYER_ADDRESS));

    //const usdt = await getMintableERC20('0x4B466AeAa9c5f639fE7eA5A4692e9ca34afD9CC6');
    //console.log(await usdt.balanceOf('0x0CED2232A2A6f9d56653A2736442108b2253BDd7'));
    */
  }
);
