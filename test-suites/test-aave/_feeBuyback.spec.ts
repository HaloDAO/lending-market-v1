import { makeSuite, TestEnv } from './helpers/make-suite';
import { timeLatest } from '../../helpers/misc-utils';
import { formatEther, parseEther } from 'ethers/lib/utils';
import { expect } from 'chai';
import { getUniswapV2Pair } from '../../helpers/contracts-getters';
makeSuite('Fee BuyBack', (testEnv: TestEnv) => {
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
    INITIAL_POOL_LIQUIDITY: parseEther('1000000'),
    EXPECTED_RNBW_IN_VESTING_SINGLE: '996.00698',
    EXPECTED_RNBW_IN_VESTING_MULTIPLE: '4960.26121',
    MIN_RNBW_FAIL: parseEther('1000000'),
  };

  it('setups the testing environment ', async () => {
    const { dai, usdc, xsgd, deployer, pool, curveFactoryMock, rnbwContract, treasuryContract, uniswapV2Factory } =
      testEnv;

    await rnbwContract.mint(deployer.address, TEST_CONSTANTS.INTIAL_RNBW_MINT);
    expect(await rnbwContract.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.INTIAL_RNBW_MINT);

    const curveMockDaiAddress = await curveFactoryMock.getCurve(dai.address, usdc.address);
    const curveMockXSGDAddress = await curveFactoryMock.getCurve(xsgd.address, usdc.address);

    // split the usdc to two mock curves equally
    await usdc.mint(TEST_CONSTANTS.INITIAL_USDC_MINT);
    await usdc.transfer(curveMockDaiAddress, TEST_CONSTANTS.INITIAL_USDC_MINT.div(2));
    await usdc.transfer(curveMockXSGDAddress, TEST_CONSTANTS.INITIAL_USDC_MINT.div(2));
    expect(await usdc.balanceOf(curveMockDaiAddress)).to.equal(TEST_CONSTANTS.INITIAL_USDC_MINT.div(2));
    expect(await usdc.balanceOf(curveMockXSGDAddress)).to.equal(TEST_CONSTANTS.INITIAL_USDC_MINT.div(2));

    await dai.mint(TEST_CONSTANTS.INTIAL_DAI_MINT);
    await dai.approve(pool.address, TEST_CONSTANTS.INTIAL_DAI_MINT);

    await xsgd.mint(TEST_CONSTANTS.INITIAL_XSGD_MINT);
    await xsgd.approve(pool.address, TEST_CONSTANTS.INITIAL_XSGD_MINT);

    // Sushi pool mock setup
    const usdcrnbwpool = await uniswapV2Factory.getPair(usdc.address, rnbwContract.address);

    await usdc.mint(TEST_CONSTANTS.INITIAL_POOL_LIQUIDITY);
    await usdc.transfer(usdcrnbwpool, TEST_CONSTANTS.INITIAL_POOL_LIQUIDITY);
    await rnbwContract.mint(usdcrnbwpool, TEST_CONSTANTS.INITIAL_POOL_LIQUIDITY);

    const slpContract = await getUniswapV2Pair(usdcrnbwpool);
    await slpContract.mint(deployer.address);
  });

  it('converts a specified aToken fees to RNBW and sends to the vesting contract', async () => {
    const { dai, aDai, pool, deployer, treasuryContract, rnbwContract, vestingContractMock } = testEnv;

    expect(await rnbwContract.balanceOf(treasuryContract.address)).to.equal(0);
    await pool.deposit(dai.address, TEST_CONSTANTS.DAI_DEPOSIT, deployer.address, 0);
    expect(await aDai.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);
    await aDai.transfer(treasuryContract.address, TEST_CONSTANTS.DAI_DEPOSIT);
    expect(await aDai.balanceOf(treasuryContract.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);
    await expect(
      treasuryContract.buybackRnbw([dai.address], 0, Number(await timeLatest())),
      'Single Token: Buyback failed'
    ).to.not.be.reverted;

    expect(await Number(formatEther(await rnbwContract.balanceOf(vestingContractMock.address))).toFixed(5)).to.equal(
      TEST_CONSTANTS.EXPECTED_RNBW_IN_VESTING_SINGLE
    );
  });
  it('converts multiple aToken fees to RNBW and sends to the vesting contract', async () => {
    const { dai, aDai, xsgd, aXSGD, pool, deployer, treasuryContract, rnbwContract, vestingContractMock } = testEnv;

    await pool.deposit(dai.address, TEST_CONSTANTS.DAI_DEPOSIT, deployer.address, 0);
    expect(await aDai.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);
    await aDai.transfer(treasuryContract.address, TEST_CONSTANTS.DAI_DEPOSIT);
    expect(await aDai.balanceOf(treasuryContract.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);

    await pool.deposit(xsgd.address, TEST_CONSTANTS.XSGD_DEPOSIT, deployer.address, 0);
    expect(await aXSGD.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.XSGD_DEPOSIT);
    await aXSGD.transfer(treasuryContract.address, TEST_CONSTANTS.XSGD_DEPOSIT);
    expect(await aXSGD.balanceOf(treasuryContract.address)).to.equal(TEST_CONSTANTS.XSGD_DEPOSIT);

    await expect(
      treasuryContract.buybackRnbw([dai.address, xsgd.address], 0, Number(await timeLatest())),
      'Multiple Token: Buyback Failed'
    ).to.not.be.reverted;

    expect(await Number(formatEther(await rnbwContract.balanceOf(vestingContractMock.address))).toFixed(5)).to.equal(
      TEST_CONSTANTS.EXPECTED_RNBW_IN_VESTING_MULTIPLE
    );
  });

  it('reverts if converted value is less than minRNBWAmount for convert()', async () => {
    const { dai, aDai, pool, deployer, treasuryContract } = testEnv;

    await pool.deposit(dai.address, TEST_CONSTANTS.DAI_DEPOSIT, deployer.address, 0);
    expect(await aDai.balanceOf(deployer.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);
    await aDai.transfer(treasuryContract.address, TEST_CONSTANTS.DAI_DEPOSIT);
    expect(await aDai.balanceOf(treasuryContract.address)).to.equal(TEST_CONSTANTS.DAI_DEPOSIT);

    await expect(
      treasuryContract.buybackRnbw([dai.address], TEST_CONSTANTS.MIN_RNBW_FAIL, Number(await timeLatest())),
      'minRNBW amount is expected'
    ).to.be.revertedWith('Treasury: rnbwAmount is less than minRNBWAmount');
  });

  it('reverts if caller is not owner for buybackRnbw()', async () => {
    const { dai, secondaryWallet, treasuryContract } = testEnv;

    await expect(
      treasuryContract.connect(secondaryWallet.signer).buybackRnbw([dai.address], 0, Number(await timeLatest())),
      'Caller is the owner'
    ).to.be.revertedWith('Ownable: caller is not the owner');
  });

  it('should revert if we convert tokens not in the curveFactory', async () => {
    const { treasuryContract, thkd } = testEnv;

    await expect(
      treasuryContract.buybackRnbw([thkd.address], 0, Number(await timeLatest())),
      'Underlying token has as curve counterpart'
    ).to.be.revertedWith('revert 1');
  });
});
