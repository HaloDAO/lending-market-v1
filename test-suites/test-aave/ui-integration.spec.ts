import { makeSuite } from './helpers/make-suite';
import { expect } from 'chai';
import { convertToCurrencyDecimals } from '../../helpers/contracts-helpers';
import { APPROVAL_AMOUNT_LENDING_POOL } from '../../helpers/constants';

makeSuite('UI integration tests', async (testEnv) => {
  it('App displays market data for each reserve', async () => {
    const { pool } = testEnv;

    const reservesList = await pool.getReservesList();

    for (let i = 0; i < reservesList.length; i++) {
      const reserveData = await pool.getReserveData(reservesList[i]);
      expect(reserveData).is.not.null;
    }
  });

  it('User can deposit DAI', async () => {
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
});
