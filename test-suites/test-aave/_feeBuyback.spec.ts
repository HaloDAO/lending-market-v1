import { ProtocolErrors } from '../../helpers/types';
import { makeSuite, TestEnv } from './helpers/make-suite';

import { DRE, getDb, increaseTime } from '../../helpers/misc-utils';
import { eContractid } from '../../helpers/types';
import { formatEther, parseEther } from 'ethers/lib/utils';
import { expect } from 'chai';
makeSuite('Fee BuyBack', (testEnv: TestEnv) => {
  const { INVALID_FROM_BALANCE_AFTER_TRANSFER, INVALID_TO_BALANCE_AFTER_TRANSFER, VL_TRANSFER_NOT_ALLOWED } =
    ProtocolErrors;

  // constants
  const TEST_CONSTANTS = {
    INTIAL_RNBW_MINT: parseEther('10000000'),
    INTIAL_DAI_MINT: parseEther('20000'),
    INITIAL_XSGD_MINT: parseEther('50000'),
    INITIAL_USDC_MINT: parseEther('20000000'),
    DAI_DEPOSIT: parseEther('1000'),
    DAI_DEPOSIT_2: parseEther('500'),
    XSGD_DEPOSIT: parseEther('3000'),
    EMMISSION_PER_SECOND: parseEther('1'),
    FIRST_BORROW_AMOUNT: parseEther('100'),
    SECOND_BORROW_AMOUNT: parseEther('500'),
    INCREASE_TIME: 10,
    INCREASE_TIME_2: 1000,
  };

  /**
   * TODO: Mock uniswap using waffle to test contract
   * TODO: Use Treasury my version
   * TODO: Sync to latest master
   */

  it('setups the testing environment ', async () => {
    const { dai, usdc, xsgd, deployer, pool, curveFactoryMock, rnbwContract, treasuryContract } = testEnv;
    const uniswapMockAddress = await treasuryContract.router();
    await rnbwContract.mint(deployer.address, TEST_CONSTANTS.INTIAL_RNBW_MINT);
    expect(await rnbwContract.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.INTIAL_RNBW_MINT);
    await rnbwContract.transfer(uniswapMockAddress, TEST_CONSTANTS.INTIAL_RNBW_MINT);
    const curveMockDaiAddress = await curveFactoryMock.getCurve(dai.address, usdc.address);
    const curveMockXSGDAddress = await curveFactoryMock.getCurve(xsgd.address, usdc.address);

    await usdc.mint(TEST_CONSTANTS.INITIAL_USDC_MINT);
    await usdc.transfer(curveMockDaiAddress, TEST_CONSTANTS.INITIAL_USDC_MINT.div(2));
    await usdc.transfer(curveMockXSGDAddress, TEST_CONSTANTS.INITIAL_USDC_MINT.div(2));
    expect(await usdc.balanceOf(curveMockDaiAddress)).to.equal(TEST_CONSTANTS.INITIAL_USDC_MINT.div(2));
    expect(await usdc.balanceOf(curveMockXSGDAddress)).to.equal(TEST_CONSTANTS.INITIAL_USDC_MINT.div(2));

    await dai.mint(parseEther('20000'));
    await dai.approve(pool.address, parseEther('20000'));

    await xsgd.mint(parseEther('50000'));
    await xsgd.approve(pool.address, parseEther('50000'));
  });

  it('converts a specified aToken fees to RNBW and sends to the vesting contract', async () => {
    const { dai, aDai, pool, deployer, treasuryContract, rnbwContract } = testEnv;
    expect(await rnbwContract.balanceOf(treasuryContract.address)).to.equal(0);
    await pool.deposit(dai.address, TEST_CONSTANTS.DAI_DEPOSIT, deployer.address, 0);
    expect(await aDai.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);
    await aDai.transfer(treasuryContract.address, TEST_CONSTANTS.DAI_DEPOSIT);
    expect(await aDai.balanceOf(treasuryContract.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);
    await expect(treasuryContract.buybackRnbw([dai.address])).to.not.be.reverted;

    expect(await rnbwContract.balanceOf(treasuryContract.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT.mul(2)); // from the mock
  });
  it('converts multiple aToken fees to RNBW and sends to the vesting contract', async () => {
    const {
      dai,
      aDai,
      usdc,
      xsgd,
      aXSGD,
      pool,
      deployer,
      secondaryWallet,
      treasuryContract,
      curveFactoryMock,
      rnbwContract,
    } = testEnv;

    await pool.deposit(dai.address, TEST_CONSTANTS.DAI_DEPOSIT, deployer.address, 0);
    expect(await aDai.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);
    await aDai.transfer(treasuryContract.address, TEST_CONSTANTS.DAI_DEPOSIT);
    expect(await aDai.balanceOf(treasuryContract.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);

    await pool.deposit(xsgd.address, TEST_CONSTANTS.XSGD_DEPOSIT, deployer.address, 0);
    expect(await aXSGD.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.XSGD_DEPOSIT);

    await aXSGD.transfer(treasuryContract.address, TEST_CONSTANTS.XSGD_DEPOSIT);
    expect(await aXSGD.balanceOf(treasuryContract.address)).to.equal(TEST_CONSTANTS.XSGD_DEPOSIT);

    console.log(
      `aXSGD: ${formatEther(await aXSGD.balanceOf(treasuryContract.address))}, aDAI: ${formatEther(
        await aDai.balanceOf(treasuryContract.address)
      )}`
    );

    await treasuryContract.buybackRnbw([dai.address, xsgd.address]);
  });
  it('reverts if converted value is less than minRNBWAmount for convert()', async () => {
    const {
      dai,
      aDai,
      usdc,
      xsgd,
      aXSGD,
      pool,
      deployer,
      secondaryWallet,
      treasuryContract,
      curveFactoryMock,
      rnbwContract,
    } = testEnv;
  });
  it('reverts if caller is not owner for buybackRnbw()', async () => {
    const { dai, secondaryWallet, treasuryContract } = testEnv;

    await expect(treasuryContract.connect(secondaryWallet.signer).buybackRnbw([dai.address])).to.be.revertedWith(
      'Ownable: caller is not the owner'
    );
  });

  it('should revert if we convert tokens not in the curveFactory', async () => {
    const { treasuryContract, thkd } = testEnv;

    await expect(treasuryContract.buybackRnbw([thkd.address])).to.be.revertedWith('revert 1');
  }); // TODO: Change pot of gold test description also

  it.skip('buyback test', async () => {
    const {
      dai,
      aDai,
      usdc,
      xsgd,
      aXSGD,
      pool,
      deployer,
      secondaryWallet,
      treasuryContract,
      curveFactoryMock,
      rnbwContract,
    } = testEnv;
    await dai.mint(parseEther('20000'));
    await dai.approve(pool.address, parseEther('20000'));

    await pool.deposit(dai.address, parseEther('20000'), deployer.address, 0);

    const treasuryAddress = treasuryContract.address;

    const rnbwAddress = await rnbwContract.address;
    console.log(`Rnbw Address: ${rnbwAddress}`);

    const vestingContractMock = await getDb().get(`${eContractid.VestingContractMock}.${DRE.network.name}`).value();
    const vestingContractAddress = vestingContractMock.address;

    const uniswapMockAddress = await treasuryContract.router();
    console.log(uniswapMockAddress);
    console.log(treasuryAddress);

    //set as collateral
    await pool.setUserUseReserveAsCollateral(dai.address, true);

    //deposit xsgd
    await xsgd.connect(secondaryWallet.signer).mint(parseEther('50000'));

    await xsgd.connect(secondaryWallet.signer).approve(pool.address, parseEther('50000'));
    await pool.connect(secondaryWallet.signer).deposit(xsgd.address, parseEther('20000'), secondaryWallet.address, 0);

    increaseTime(600);

    //borrow 2
    await pool.connect(secondaryWallet.signer).borrow(dai.address, parseEther('1000'), 2, 0, secondaryWallet.address);
    increaseTime(600);

    await pool.connect(secondaryWallet.signer).borrow(dai.address, parseEther('1000'), 2, 0, secondaryWallet.address);
    increaseTime(600);
    //check balance
    console.log(await aDai.balanceOf(treasuryAddress));
    console.log(await aXSGD.balanceOf(treasuryAddress));
    console.log(await rnbwContract.balanceOf(deployer.address));
    await rnbwContract.mint(deployer.address, parseEther('10000000'));
    console.log(`Deployer has rnbw tokens: ${await rnbwContract.balanceOf(deployer.address)}`);
    await rnbwContract.transfer(uniswapMockAddress, parseEther('10000000'));
    const curveMockDaiAddress = await curveFactoryMock.getCurve(dai.address, usdc.address);
    console.log(`curveMockDaiAddress: ${curveMockDaiAddress}`);
    await usdc.mint(parseEther('10000000'));
    console.log(`Deployer has usdc tokens: ${await usdc.balanceOf(deployer.address)}`);
    await usdc.transfer(curveMockDaiAddress, parseEther('10000000'));
    console.log(`Uniswap Contract Rnbw balance initial: ${await rnbwContract.balanceOf(uniswapMockAddress)}`);
    console.log(`Treasury Contract Rnbw balance initial: ${await rnbwContract.balanceOf(treasuryAddress)}`);
    console.log('Buy back rnbw ...');
    await treasuryContract.buybackRnbw([dai.address]);

    console.log(`Treasury Contract Rnbw balance final: ${await rnbwContract.balanceOf(treasuryAddress)}`);

    console.log(`Vesting Contract Rnbw balance initial: ${await rnbwContract.balanceOf(vestingContractAddress)}`);

    console.log('Send rnbw to vesting ...');

    await treasuryContract.sendToVestingContract();
    console.log(`Vesting Contract Rnbw balance final: ${await rnbwContract.balanceOf(vestingContractAddress)}`);
  });
});
