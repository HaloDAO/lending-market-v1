import {
  APPROVAL_AMOUNT_LENDING_POOL,
  MAX_UINT_AMOUNT,
  ZERO_ADDRESS,
} from '../../helpers/constants';
import { convertToCurrencyDecimals } from '../../helpers/contracts-helpers';
import { expect } from 'chai';
import { ethers } from 'ethers';
import { RateMode, ProtocolErrors } from '../../helpers/types';
import {
  getRnbwMock,
  getTreasury,
  getMockEmissionManager,
  getRnbwIncentivesController,
} from '../../helpers/contracts-getters';
import { makeSuite, TestEnv } from './helpers/make-suite';
import { CommonsConfig } from '../../markets/aave/commons';
const { parseEther } = ethers.utils;
import { DRE, getDb, notFalsyOrZeroAddress, increaseTime } from '../../helpers/misc-utils';
import {
  tEthereumAddress,
  eContractid,
  tStringTokenSmallUnits,
  eEthereumNetwork,
  AavePools,
  iParamsPerNetwork,
  iParamsPerPool,
  ePolygonNetwork,
  eXDaiNetwork,
  eNetwork,
  iParamsPerNetworkAll,
  iEthereumParamsPerNetwork,
  iPolygonParamsPerNetwork,
  iXDaiParamsPerNetwork,
} from '../../helpers/types';
makeSuite('Incentives Controller', (testEnv: TestEnv) => {
  const {
    INVALID_FROM_BALANCE_AFTER_TRANSFER,
    INVALID_TO_BALANCE_AFTER_TRANSFER,
    VL_TRANSFER_NOT_ALLOWED,
  } = ProtocolErrors;

  it('steak', async () => {
    //setup
    const { dai, aDai, weth, aWETH, xsgd, aXSGD, pool, deployer, secondaryWallet } = testEnv;
    console.log(`deployer.address: ${deployer.address}`);
    console.log(`secondaryWallet.address: ${secondaryWallet.address}`);
    const rnbwContract = await getRnbwMock();
    const rnbwAddress = rnbwContract.address;
    console.log(`Rnbw Address: ${rnbwAddress}`);

    const emissionManager = await getMockEmissionManager();
    // const emissionManagerAddress = await emissionManager.address;

    const rnbwIncentivesController = await getRnbwIncentivesController();
    // const rnbwIncentivesControllerAddress = await rnbwIncentivesController.address;

    console.log(`emissionManager: ${emissionManager.address}`);
    console.log(`rnbwIncentivesController: ${rnbwIncentivesController.address}`);
    console.log(
      `emissionManager rnbwIncentivesController: ${await rnbwIncentivesController.EMISSION_MANAGER()}`
    );

    console.log(
      `incentives Controller set on emission manager: ${await emissionManager.incentivesController()}`
    );
    //mint rnbw to deployer
    await rnbwContract.mint(deployer.address, parseEther('10000000'));

    //send rnbw to incentivesController
    await rnbwContract.transfer(rnbwIncentivesController.address, parseEther('10000000'));

    //set up emission rate
    //set up emission rate for dai
    // await emissionManager.configure([[parseEther('10'), 0, dai.address]])
    await emissionManager.configure([
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: aDai.address,
      },
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: aXSGD.address,
      },
    ]);
    console.log(`incentivesController dai: ${await rnbwIncentivesController.assets(aDai.address)}`);
    console.log(
      `incentivesController xsgd: ${await rnbwIncentivesController.assets(aXSGD.address)}`
    );

    //deposit
    await dai.mint(parseEther('20000'));
    await dai.approve(pool.address, parseEther('20000'));
    await pool.deposit(dai.address, parseEther('2000'), deployer.address, 0);
    console.log(`aDAI balance user after deposit: ${await aDai.balanceOf(deployer.address)}`);
    await pool.setUserUseReserveAsCollateral(dai.address, true);
    //deposit weth
    console.log(dai.address);

    await xsgd.connect(secondaryWallet).mint(parseEther('50000'));
    await xsgd.connect(secondaryWallet).approve(pool.address, parseEther('50000'));
    await pool
      .connect(secondaryWallet)
      .deposit(xsgd.address, parseEther('20000'), secondaryWallet.address, 0);
    await pool.connect(secondaryWallet).setUserUseReserveAsCollateral(xsgd.address, true);

    increaseTime(600);

    //deposit 2
    await pool.deposit(dai.address, parseEther('2000'), deployer.address, 0);
    await pool
      .connect(secondaryWallet)
      .deposit(xsgd.address, parseEther('20000'), secondaryWallet.address, 0);

    //borrow 2
    await pool
      .connect(secondaryWallet)
      .borrow(dai.address, parseEther('1000'), 1, 0, secondaryWallet.address);
    increaseTime(600);

    //borrow 4
    await pool
      .connect(secondaryWallet)
      .borrow(dai.address, parseEther('500'), 1, 0, secondaryWallet.address);
    increaseTime(600);

    //get rewards
    console.log(
      `User Unclaimed rewards: ${await rnbwIncentivesController.getUserUnclaimedRewards(
        deployer.address
      )}`
    );
    console.log(
      `User RewardsBalance: ${await rnbwIncentivesController.getRewardsBalance(
        [aDai.address],
        deployer.address
      )}`
    );
    console.log(
      `User 2 Unclaimed rewards: ${await rnbwIncentivesController.getUserUnclaimedRewards(
        secondaryWallet.address
      )}`
    );
    console.log(
      `User 2 RewardsBalance: ${await rnbwIncentivesController.getRewardsBalance(
        [aDai.address],
        secondaryWallet.address
      )}`
    );

    //claim rewards
  });
});
