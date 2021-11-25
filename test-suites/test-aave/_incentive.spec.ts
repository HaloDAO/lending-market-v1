import { expect } from 'chai';
import { ethers } from 'ethers';
import { makeSuite, TestEnv } from './helpers/make-suite';
const { parseEther } = ethers.utils;
import { increaseTime } from '../../helpers/misc-utils';
import { formatEther } from 'ethers/lib/utils';

makeSuite('Incentives Controller', (testEnv: TestEnv) => {
  // constants
  const TEST_CONSTANTS = {
    INTIAL_RNBW_MINT: parseEther('10000000'),
    INTIAL_DAI_MINT: parseEther('20000'),
    INITIAL_XSGD_MINT: parseEther('50000'),
    DAI_DEPOSIT: parseEther('2000'),
    DAI_DEPOSIT_2: parseEther('500'),
    XSGD_DEPOSIT: parseEther('20000'),
    EMMISSION_PER_SECOND: parseEther('1'),
    FIRST_BORROW_AMOUNT: parseEther('100'),
    SECOND_BORROW_AMOUNT: parseEther('500'),
    INCREASE_TIME: 10,
    INCREASE_TIME_2: 1000,
  };

  it('should set the incentives controller and emission manager properly', async () => {
    const { emissionManager, rnbwIncentivesController } = testEnv;
    expect(
      await rnbwIncentivesController.EMISSION_MANAGER(),
      'Emission manager in incentives controller is not equal to deployed emission manager'
    ).to.equal(emissionManager.address);
    expect(
      await emissionManager.incentivesController(),
      'Incentives controller inside emission manager is not equal to deployed incentives controller'
    ).to.equal(rnbwIncentivesController.address);
  });

  // ? - mock xRNBW as reward token instead by changing or need to add vesting contract?
  it('should mint rnbw rewards to the incentives controller', async () => {
    const { deployer, rnbwContract, rnbwIncentivesController } = testEnv;

    await rnbwContract.mint(deployer.address, TEST_CONSTANTS.INTIAL_RNBW_MINT);
    await rnbwContract.transfer(rnbwIncentivesController.address, TEST_CONSTANTS.INTIAL_RNBW_MINT);
    expect(await rnbwContract.balanceOf(rnbwIncentivesController.address)).to.equal(TEST_CONSTANTS.INTIAL_RNBW_MINT);
  });

  it('should configure emission manager without revert', async () => {
    const { aDai, aXSGD, emissionManager, rnbwIncentivesController } = testEnv;

    await expect(
      emissionManager.configure([
        {
          emissionPerSecond: TEST_CONSTANTS.EMMISSION_PER_SECOND,
          totalStaked: 0,
          underlyingAsset: aDai.address,
        },
        {
          emissionPerSecond: TEST_CONSTANTS.EMMISSION_PER_SECOND,
          totalStaked: 0,
          underlyingAsset: aXSGD.address,
        },
      ])
    ).to.not.be.reverted;

    const assetDataDai = await rnbwIncentivesController.assets(aDai.address);
    expect(assetDataDai[0]).to.equal(TEST_CONSTANTS.EMMISSION_PER_SECOND);
    const assetDataXSGD = await rnbwIncentivesController.assets(aXSGD.address);
    expect(assetDataXSGD[0]).to.equal(TEST_CONSTANTS.EMMISSION_PER_SECOND);
  });

  it('earn reward when depositing to lending pool', async () => {
    const { dai, aDai, pool, deployer, rnbwIncentivesController, secondaryWallet } = testEnv;

    await dai.mint(TEST_CONSTANTS.INTIAL_DAI_MINT);
    await dai.connect(secondaryWallet.signer).mint(TEST_CONSTANTS.INTIAL_DAI_MINT);
    await dai.approve(pool.address, TEST_CONSTANTS.INTIAL_RNBW_MINT);
    await dai.connect(secondaryWallet.signer).approve(pool.address, TEST_CONSTANTS.INTIAL_RNBW_MINT);

    await expect(pool.deposit(dai.address, TEST_CONSTANTS.DAI_DEPOSIT, deployer.address, 0)).to.not.be.reverted;
    expect(await aDai.balanceOf(deployer.address), 'aDai balance for secondaryWallet is not accurate').to.equal(
      TEST_CONSTANTS.DAI_DEPOSIT
    );
    await increaseTime(TEST_CONSTANTS.INCREASE_TIME);

    expect(
      Number(formatEther(await rnbwIncentivesController.getRewardsBalance([aDai.address], deployer.address))),
      'Rewards emission not accurate.'
    ).to.equal(TEST_CONSTANTS.INCREASE_TIME); // sometimes block time increases + 1 second

    await expect(
      pool
        .connect(secondaryWallet.signer)
        .deposit(dai.address, TEST_CONSTANTS.DAI_DEPOSIT_2, secondaryWallet.address, 0)
    ).to.not.be.reverted;

    expect(await aDai.balanceOf(secondaryWallet.address), 'aDai balance for secondaryWallet is not accurate').to.equal(
      TEST_CONSTANTS.DAI_DEPOSIT_2
    );

    await increaseTime(TEST_CONSTANTS.INCREASE_TIME_2);

    expect(
      Number(formatEther(await rnbwIncentivesController.getRewardsBalance([aDai.address], deployer.address))),
      `Rewards for deployer after  ${TEST_CONSTANTS.INCREASE_TIME_2} seconds is not accurate`
    ).to.equal(
      Number(formatEther(TEST_CONSTANTS.EMMISSION_PER_SECOND)) *
        TEST_CONSTANTS.INCREASE_TIME_2 *
        (Number(formatEther(await aDai.balanceOf(deployer.address))) / Number(formatEther(await aDai.totalSupply())))
    );

    expect(
      Number(formatEther(await rnbwIncentivesController.getRewardsBalance([aDai.address], secondaryWallet.address))),
      `Rewards for secondaryWallet after ${TEST_CONSTANTS.INCREASE_TIME_2} seconds is not accurate`
    ).to.equal(
      Number(formatEther(TEST_CONSTANTS.EMMISSION_PER_SECOND)) *
        TEST_CONSTANTS.INCREASE_TIME_2 *
        (Number(formatEther(await aDai.balanceOf(secondaryWallet.address))) /
          Number(formatEther(await aDai.totalSupply())))
    );
  });

  it('collateral earn rewards when borrowing to the lending pool', async () => {
    const { users, xsgd, dai, pool, aXSGD, rnbwIncentivesController } = testEnv;

    await xsgd.connect(users[2].signer).mint(TEST_CONSTANTS.INITIAL_XSGD_MINT);
    await xsgd.connect(users[2].signer).approve(pool.address, TEST_CONSTANTS.INITIAL_XSGD_MINT);
    await pool.connect(users[2].signer).deposit(xsgd.address, TEST_CONSTANTS.XSGD_DEPOSIT, users[2].address, 0);
    expect(await aXSGD.balanceOf(users[2].address), 'aXSGD is not equal to deposit value').to.equal(
      TEST_CONSTANTS.XSGD_DEPOSIT
    );
    await expect(pool.connect(users[2].signer).setUserUseReserveAsCollateral(xsgd.address, true)).to.not.be.reverted;

    await expect(
      pool.connect(users[2].signer).borrow(dai.address, TEST_CONSTANTS.FIRST_BORROW_AMOUNT, 1, 0, users[2].address)
    ).to.not.be.reverted;

    await increaseTime(TEST_CONSTANTS.INCREASE_TIME);

    expect(
      Number(formatEther(await rnbwIncentivesController.getRewardsBalance([aXSGD.address], users[2].address))),
      'Rewards balance is not accurate'
    ).to.equal(TEST_CONSTANTS.INCREASE_TIME + 2); // 2 txns after deposit txn, might increase + 1
  });

  it('should claim reward amount less than current rewards balance', async () => {
    const { deployer, aDai, rnbwIncentivesController, rnbwContract } = testEnv;

    expect(await rnbwContract.balanceOf(deployer.address)).to.be.equal(0);

    const daiRewards = await rnbwIncentivesController.getRewardsBalance([aDai.address], deployer.address);
    const rewardsToClaim = daiRewards.sub(parseEther('10'));

    await expect(
      rnbwIncentivesController.claimRewards([aDai.address], rewardsToClaim, deployer.address, false),
      'Rewards claiming failed'
    ).to.emit(rnbwIncentivesController, 'RewardsClaimed').to.not.be.reverted;

    expect(await rnbwContract.balanceOf(deployer.address)).to.be.equal(rewardsToClaim);
  });

  it('should be able to claim the exact reward of the user from the incentives controller', async () => {
    const { secondaryWallet, aDai, rnbwIncentivesController, rnbwContract } = testEnv;

    expect(await rnbwContract.balanceOf(secondaryWallet.address)).to.be.equal(0);

    const daiRewards = await rnbwIncentivesController.getRewardsBalance([aDai.address], secondaryWallet.address);

    await expect(
      rnbwIncentivesController
        .connect(secondaryWallet.signer)
        .claimRewards([aDai.address], daiRewards, secondaryWallet.address, false),
      'Rewards claiming failed'
    ).to.emit(rnbwIncentivesController, 'RewardsClaimed').to.not.be.reverted;

    expect(await rnbwContract.balanceOf(secondaryWallet.address)).to.be.equal(daiRewards);
  });

  it('should be able to send rewards claimed to other address specified by user', async () => {
    const { deployer, users, aDai, rnbwIncentivesController, rnbwContract } = testEnv;

    const daiRewards = await rnbwIncentivesController.getRewardsBalance([aDai.address], deployer.address);

    await expect(
      rnbwIncentivesController.claimRewards([aDai.address], daiRewards, users[3].address, false),
      'Rewards claiming failed'
    ).to.emit(rnbwIncentivesController, 'RewardsClaimed').to.not.be.reverted;

    expect(await rnbwContract.balanceOf(users[3].address)).to.be.equal(daiRewards);
  });
});
