import { makeSuite } from './helpers/make-suite';
import { expect } from 'chai';
import { convertToCurrencyDecimals } from '../../helpers/contracts-helpers';
import { AAVE_REFERRAL, APPROVAL_AMOUNT_LENDING_POOL } from '../../helpers/constants';
import { parseEther } from '@ethersproject/units';
import { RateMode } from '../../helpers/types';

makeSuite('UI integration tests', async (testEnv) => {
  it('App displays market data for each reserve', async () => {
    const { pool } = testEnv;

    const reservesList = await pool.getReservesList();

    for (let i = 0; i < reservesList.length; i++) {
      const reserveData = await pool.getReserveData(reservesList[i]);
      expect(reserveData.configuration).is.not.null;
      expect(reserveData.currentLiquidityRate).is.not.null;
      expect(reserveData.currentVariableBorrowRate).is.not.null;
      expect(reserveData.currentStableBorrowRate).is.not.null;
    }
  });

  it('User can deposit DAI and received xDAI in return', async () => {
    const { users, pool, dai, aDai } = testEnv;

    // mint mock DAI for the user
    const depositAmount = await convertToCurrencyDecimals(dai.address, '1000');
    await dai.connect(users[0].signer).mint(depositAmount);

    // user approves LendingPool contract to use his/her DAI
    await dai.connect(users[0].signer).approve(pool.address, APPROVAL_AMOUNT_LENDING_POOL);

    // user deposits x amount to DAI market
    await pool.connect(users[0].signer).deposit(dai.address, depositAmount, users[0].address, '0');

    // user's DAI should be 0 after deposit
    const daiBalance = await dai.balanceOf(users[0].address);
    expect(daiBalance.toString()).to.be.equal('0');

    // user receives equivalent aDAI in return
    const aDaiBalance = await aDai.balanceOf(users[0].address);
    expect(aDaiBalance.toString()).to.be.equal(depositAmount.toString());
  });

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

  it('User can borrow ETH using DAI as collateral', async () => {
    const { users, pool, aDai, weth } = testEnv;

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
});
