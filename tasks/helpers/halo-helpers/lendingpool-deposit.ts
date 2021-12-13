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

const isSymbolValid = (symbol: string, network: eEthereumNetwork) =>
  Object.keys(reserveConfigs).includes('strategy' + symbol) &&
  marketConfigs.HaloConfig.ReserveAssets[network][symbol] &&
  marketConfigs.HaloConfig.ReservesConfig[symbol] === reserveConfigs['strategy' + symbol];

task('external:lendingpool-deposit', 'Initialize incentives controller').setAction(
  async ({ verify, symbol }, localBRE) => {
    const network = localBRE.network.name;

    const DEPLOYER_ADDRESS = '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd';
    const TEST_ASSET = '0x4B466AeAa9c5f639fE7eA5A4692e9ca34afD9CC6';

    setDRE(localBRE);
    const lendingPool = await getLendingPool('0x0532bAA43AA6f52BCb0aA06d923Fcb81b07E01A6');

    const lendingPoolOld = await getLendingPool('0x5AD20e34cA5EA2ed3C987Cb01b6A65f21C42c4b1');

    const token = await getMintableERC20(TEST_ASSET);

    //  await token.mint(parseEther('1000000'));

    // console.log(await token.balanceOf(DEPLOYER_ADDRESS));

    //console.log(await lendingPool.getUserAccountData(DEPLOYER_ADDRESS));

    // address, amount, to, 0
    console.log(await lendingPool.deposit(TEST_ASSET, parseEther('1'), DEPLOYER_ADDRESS, 0));

    // console.log(await lendingPool.getReserveData(TEST_ASSET));

    //console.log(await lendingPool.getReservesList());
    //
    //console.log(await lendingPoolOld.getReservesList());
  }
);
