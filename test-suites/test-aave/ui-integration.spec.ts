import { makeSuite } from './helpers/make-suite';
import { expect } from 'chai';
import { convertToCurrencyDecimals } from '../../helpers/contracts-helpers';
import { AAVE_REFERRAL, MAX_UINT_AMOUNT } from '../../helpers/constants';
import { parseEther } from '@ethersproject/units';
import { RateMode } from '../../helpers/types';
import { getStableDebtToken } from '../../helpers/contracts-getters';
import { BigNumber } from '@ethersproject/bignumber';

makeSuite('UI integration tests', async (testEnv) => {
  const ZERO = BigNumber.from('0');

  /**
   * Markets
   */
  it('App displays market data for each reserve', async () => {
    const { addressesProvider, uiDataProvider, users } = testEnv;

    // Fetch detail of all reserves
    const {
      0: rawReservesData,
      1: userReserves,
      2: usdPriceEth,
      3: rawRewardsData,
    } = await uiDataProvider.getReservesData(addressesProvider.address, users[0].address);

    // Basic assertions
    expect(rawReservesData).is.not.empty;
    expect(userReserves).is.not.empty;
    expect(usdPriceEth).is.not.null;
    expect(rawRewardsData).is.not.null;

    // Displaying of data on the market table
    for (let i = 0; i < rawReservesData.length; i++) {
      expect(rawReservesData[i].symbol).is.not.null; // Asset column
      // @todo: Market Size column
      expect(userReserves[i].principalStableDebt).is.not.null; // Total Borrowed column
      expect(rawReservesData[i].liquidityRate).is.not.null; // Deposit APY column
      expect(rawReservesData[i].stableBorrowRate).is.not.null; // Borrow APY column
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
    await pool.connect(users[0].signer).deposit(dai.address, depositAmount, users[0].address, AAVE_REFERRAL);

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
    const { users, dai, pool, uiDataProvider, addressesProvider } = testEnv;

    // verify by default DAI is used as collateral
    const { 0: userReservesBefore } = await uiDataProvider.getUserReservesData(
      addressesProvider.address,
      users[0].address
    );
    const daiReserveBefore = userReservesBefore.find((reserve) => reserve.underlyingAsset === dai.address);
    expect(daiReserveBefore.usageAsCollateralEnabledOnUser).to.be.true;

    // unset DAI as collateral
    await pool.connect(users[0].signer).setUserUseReserveAsCollateral(dai.address, false);

    // verify DAI is not used as collateral
    const { 0: userReservesAfter } = await uiDataProvider.getUserReservesData(
      addressesProvider.address,
      users[0].address
    );
    const daiReserveAfter = userReservesAfter.find((reserve) => reserve.underlyingAsset === dai.address);
    expect(daiReserveAfter.usageAsCollateralEnabledOnUser).to.be.false;

    // Revert to use DAI as collateral
    await pool.connect(users[0].signer).setUserUseReserveAsCollateral(dai.address, true);
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
    await pool.connect(users[1].signer).deposit(weth.address, depositAmount, users[1].address, AAVE_REFERRAL);

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
  it('User can fully repay ETH loan', async () => {
    const { users, pool, weth, helpersContract } = testEnv;

    // verify debt balance is > 0
    const { stableDebtTokenAddress } = await helpersContract.getReserveTokensAddresses(weth.address);
    const stableDebtToken = await getStableDebtToken(stableDebtTokenAddress);
    const debtBalanceBefore = await stableDebtToken.balanceOf(users[0].address);
    expect(debtBalanceBefore).to.be.gt(ZERO);

    // mint some more ETH so user can pay for loan interest
    const interestAmount = await convertToCurrencyDecimals(weth.address, '0.001'); // @todo: how much interest to pay?
    await weth.connect(users[0].signer).mint(interestAmount);

    // user approves ETH spend to repay loan
    await weth.connect(users[0].signer).approve(pool.address, MAX_UINT_AMOUNT);

    // user fully repays ETH
    await pool.connect(users[0].signer).repay(weth.address, MAX_UINT_AMOUNT, RateMode.Stable, users[0].address);

    // borrowed amount should be deducted from user's ETH balance
    const ethBalanceAfter = await weth.balanceOf(users[0].address);
    const borrowAmount = await convertToCurrencyDecimals(weth.address, '0.01');
    expect(ethBalanceAfter).to.be.lt(borrowAmount);

    // verify debt balance is now 0
    const debtBalanceAfter = await stableDebtToken.balanceOf(users[0].address);
    expect(debtBalanceAfter).to.be.eq(ZERO);
  });

  /**
   * Withdraw
   */
  it('User can fully withdraw DAI collateral', async () => {
    const { users, pool, dai } = testEnv;

    // make sure user has 0 DAI
    const daiBalanceBefore = await dai.balanceOf(users[0].address);
    expect(daiBalanceBefore.toString()).to.be.equal('0');

    // user withdraws x amount of DAI
    const withdrawAmount = await convertToCurrencyDecimals(dai.address, '1000');
    await pool.connect(users[0].signer).withdraw(dai.address, withdrawAmount, users[0].address);

    // user gets back x amount of DAI balance after withdrawal
    const daiBalanceAfter = await dai.balanceOf(users[0].address);
    expect(daiBalanceAfter).to.be.eq(withdrawAmount);
  });
});
