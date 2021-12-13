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

const INCENTIVES_CONTROLLER = {
  kovan: '0x8Bfa7b45Ad86df7BeD67E91A676b7495B0402d04',
};

const ASSET_CONFIG = {
  kovan: [
    {
      emissionPerSecond: parseEther('1'),
      totalStaked: 0,
      underlyingAsset: '0x8C98CD6686F28b49D28e561d37F017bB456CD8C5', // TODO: Change this, aTokenAddress
    },
    {
      emissionPerSecond: parseEther('2.2'),
      totalStaked: 0,
      underlyingAsset: '0x3d754c7607433b115337F7B0544fb23b356367b5', // TODO: Change this,  aTokenAddress
    },
    {
      emissionPerSecond: parseEther('1'),
      totalStaked: 0,
      underlyingAsset: '0x0C1b4e81fC6B30ead94Cc7C0a643974183be796e', // TODO: Change this, aTokenAddress
    },
    {
      emissionPerSecond: parseEther('2.2'),
      totalStaked: 0,
      underlyingAsset: '0xE2cc327F15f04fb3607F2b7291aE8AB62908Af2B', // TODO: Change this,  aTokenAddress
    },

    {
      emissionPerSecond: parseEther('1'),
      totalStaked: 0,
      underlyingAsset: '0x5c9A3Fcc66a5d8095c303eDf6e5A5e7f73a8cb85', // TODO: Change this, aTokenAddress
    },
    {
      emissionPerSecond: parseEther('2.2'),
      totalStaked: 0,
      underlyingAsset: '0x4AfCb5323C9B49Cc24792697D44C3b52865764F7', // TODO: Change this,  aTokenAddress
    },
    {
      emissionPerSecond: parseEther('1'),
      totalStaked: 0,
      underlyingAsset: '0xB90221C40cb0f781AdFe6De02c348435a6837a0E', // TODO: Change this, aTokenAddress
    },
    {
      emissionPerSecond: parseEther('2.2'),
      totalStaked: 0,
      underlyingAsset: '0xdB74bF644F5124603973aEB211D10801a9b0BF44', // TODO: Change this,  aTokenAddress
    },

    {
      emissionPerSecond: parseEther('1'),
      totalStaked: 0,
      underlyingAsset: '0x2c585fF6E0C75677aB5E0C4c46404329917197fE', // TODO: Change this, aTokenAddress
    },
    {
      emissionPerSecond: parseEther('2.2'),
      totalStaked: 0,
      underlyingAsset: '0xe91dcBfcA6818CfE13D397211E053460A94a250D', // TODO: Change this,  aTokenAddress
    },
    {
      emissionPerSecond: parseEther('1'),
      totalStaked: 0,
      underlyingAsset: '0xCE507Bd492B840b26d314807b3beC05fe2941200', // TODO: Change this, aTokenAddress
    },
  ],
};

const isSymbolValid = (symbol: string, network: eEthereumNetwork) =>
  Object.keys(reserveConfigs).includes('strategy' + symbol) &&
  marketConfigs.HaloConfig.ReserveAssets[network][symbol] &&
  marketConfigs.HaloConfig.ReservesConfig[symbol] === reserveConfigs['strategy' + symbol];

task('external:configure-incentives-emission', 'Initialize incentives controller').setAction(
  async ({ verify, symbol }, localBRE) => {
    const network = localBRE.network.name;

    const DEPLOYER_ADDRESS = '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd';
    setDRE(localBRE);

    const rnbwIncentivesController = await getRnbwIncentivesController(INCENTIVES_CONTROLLER[network]);

    await rnbwIncentivesController.configureAssets(ASSET_CONFIG[network]);

    const assetDataUSDT = await rnbwIncentivesController.assets('0x2c585fF6E0C75677aB5E0C4c46404329917197fE');

    console.log(assetDataUSDT);
    const assetDataUSDC = await rnbwIncentivesController.assets('0xdB74bF644F5124603973aEB211D10801a9b0BF44');

    console.log(assetDataUSDC);
  }
);
