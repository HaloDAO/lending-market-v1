import { makeSuite } from './helpers/make-suite';
import { expect } from 'chai';
import { convertToCurrencyDecimals } from '../../helpers/contracts-helpers';
import { AAVE_REFERRAL, MAX_UINT_AMOUNT } from '../../helpers/constants';
import { formatEther, parseEther } from '@ethersproject/units';
import { RateMode } from '../../helpers/types';
import { getStableDebtToken } from '../../helpers/contracts-getters';
import { BigNumber } from '@ethersproject/bignumber';
import { waitForTx } from '../../helpers/misc-utils';

makeSuite('UI integration tests', async (testEnv) => {
  const ZERO = BigNumber.from('0');

  /**
   * Markets
   */
  it('App displays market data for each reserve', async () => {
    const { pool, addressesProvider, uiDataProvider, users } = testEnv;

    const reservesList = await pool.getReservesList();

    for (let i = 0; i < reservesList.length; i++) {
      const reserveData = await pool.getReserveData(reservesList[i]);
      expect(reserveData.configuration).is.not.null;
      expect(reserveData.currentLiquidityRate).is.not.null;
      expect(reserveData.currentVariableBorrowRate).is.not.null;
      expect(reserveData.currentStableBorrowRate).is.not.null;
      // const {
      //   0: rawReservesData,
      //   1: userReserves,
      //   2: usdPriceEth,
      //   3: rawRewardsData,
      // } = await uiDataProvider.getReservesData(addressesProvider.address, users[0].address);
      // console.log('userReserves: ', userReserves);
      // expect(rawReservesData).is.not.null;
    }
  });

  /**
   * Deposit
   */
  it('User can deposit DAI and received aDAI in return', async () => {
    const { users, pool, dai, aDai } = testEnv;

    // mint mock DAI for the user
    const depositAmount = await convertToCurrencyDecimals(dai.address, '1000');
    await dai.connect(users[0].signer).mint(depositAmount);

    // user approves LendingPool contract to use his/her DAI
    await dai.connect(users[0].signer).approve(pool.address, MAX_UINT_AMOUNT);

    // user deposits x amount to DAI market
    await pool
      .connect(users[0].signer)
      .deposit(dai.address, depositAmount, users[0].address, AAVE_REFERRAL);

    // user's DAI should be 0 after deposit
    const daiBalance = await dai.balanceOf(users[0].address);
    expect(daiBalance.toString()).to.be.equal('0');

    // user receives equivalent aDAI in return
    const aDaiBalance = await aDai.balanceOf(users[0].address);
    expect(aDaiBalance.toString()).to.be.equal(depositAmount.toString());
  });

  /**
   * Dashboard
   */
  it('User can set DAI as collateral', async () => {
    const { users, dai, pool } = testEnv;

    // initially, DAI should not be set as collateral
    const configBefore = await pool.connect(users[0].signer).getUserConfiguration(users[0].address);
    console.log('configBefore: ', configBefore.toString(2));
    // @todo: parse config and assert DAI is NOT set as collateral

    // set DAI as collateral
    await pool
      .connect(users[0].signer)
      .setUserUseReserveAsCollateral(dai.address, users[0].address);

    // verify DAI is now set as collateral
    const configAfter = await pool.connect(users[0].signer).getUserConfiguration(users[0].address);
    console.log('configAfter: ', configAfter.toString(2));
    // @todo: parse config and assert DAI is set as collateral
  });

  /**
   * Borrow
   */
  it('User can borrow ETH using DAI as collateral', async () => {
    const { users, pool, aDai, weth } = testEnv;

    // another user deposit ETH so we have a reserve
    const depositAmount = await convertToCurrencyDecimals(weth.address, '1000');
    await weth.connect(users[1].signer).mint(depositAmount);
    await weth.connect(users[1].signer).approve(pool.address, MAX_UINT_AMOUNT);
    await pool
      .connect(users[1].signer)
      .deposit(weth.address, depositAmount, users[1].address, AAVE_REFERRAL);

    // user should have aDAI from previous test
    const aDaiBalance = await aDai.balanceOf(users[0].address);
    expect(aDaiBalance.toString()).to.be.not.equal('0');

    // make sure user has 0 ETH before borrowing
    const ethBalanceBefore = await weth.balanceOf(users[0].address);
    expect(ethBalanceBefore.toString()).to.be.equal('0');

    // user borrows x amount of ETH
    const borrowAmount = parseEther('0.01'); // @todo: how much ETH can we borrow from 1K DAI as collateral?
    await pool
      .connect(users[0].signer)
      .borrow(weth.address, borrowAmount, RateMode.Stable, AAVE_REFERRAL, users[0].address);

    // user's ETH balance should reflect borrowed amount
    const ethBalanceAfter = await weth.balanceOf(users[0].address);
    expect(ethBalanceAfter.toString()).to.be.equal(borrowAmount.toString());
  });

  /**
   * Repay
   */
  it('User can full repay ETH loan', async () => {
    const { users, pool, weth, helpersContract } = testEnv;

    // get StableDebtToke to check for existing loan
    const { stableDebtTokenAddress } = await helpersContract.getReserveTokensAddresses(
      weth.address
    );
    const stableDebtToken = await getStableDebtToken(stableDebtTokenAddress);

    // verify debt balance is > 0
    const debtBalanceBefore = await stableDebtToken.balanceOf(users[0].address);
    expect(debtBalanceBefore).to.be.gt(ZERO);
    console.log('debtBalanceBefore: ', formatEther(debtBalanceBefore));

    // mint some more ETH so user can pay for loan interest
    const borrowAmount = await convertToCurrencyDecimals(weth.address, '0.01');
    // const interestAmount = borrowAmount;
    // await weth.connect(users[0].signer).mint(borrowAmount);

    // make sure user has enough ETH balance to repay fully
    // const repayAmount = borrowAmount.add(interestAmount);
    const repayAmount = borrowAmount;
    const ethBalanceBefore = await weth.balanceOf(users[0].address);
    expect(ethBalanceBefore).to.be.eq(repayAmount);

    // user approves ETH spend to repay loan
    await weth.connect(users[0].signer).approve(pool.address, MAX_UINT_AMOUNT);

    // user fully repays ETH
    await waitForTx(
      await pool
        .connect(users[0].signer)
        .repay(weth.address, repayAmount, RateMode.Stable, users[0].address)
    );

    // user's ETH balance should reset back to 0
    const ethBalanceAfter = await weth.balanceOf(users[0].address);
    expect(ethBalanceAfter).to.be.eq(ZERO);

    // verify debt balance is == 0
    const debtBalanceAfter = await stableDebtToken.balanceOf(users[0].address);
    expect(debtBalanceAfter).to.be.eq(ZERO);
  });

  /**
   * Withdraw
   */
  it('User can full withdraw DAI collateral', async () => {
    const { users, pool, dai, aDai } = testEnv;

    // make sure user has 0 DAI
    const daiBalanceBefore = await dai.balanceOf(users[0].address);
    expect(daiBalanceBefore.toString()).to.be.equal('0');

    // user approves aDAI spend to withdraw DAI
    // await aDai.connect(users[0].signer).approve(pool.address, MAX_UINT_AMOUNT);

    // user withdraws x amount of DAI
    const withdrawAmount = await convertToCurrencyDecimals(dai.address, '1000');
    await pool.connect(users[0].signer).withdraw(dai.address, withdrawAmount, users[0].address);

    // user gets back x amount of DAI balance after withdrawal
    const daiBalanceAfter = await dai.balanceOf(users[0].address);
    expect(daiBalanceAfter.toString()).to.be.not.equal('0');
  });
});
