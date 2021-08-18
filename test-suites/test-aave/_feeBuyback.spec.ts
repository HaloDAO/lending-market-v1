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
  getCurveFactoryMock,
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
makeSuite('Fee BuyBack', (testEnv: TestEnv) => {
  const {
    INVALID_FROM_BALANCE_AFTER_TRANSFER,
    INVALID_TO_BALANCE_AFTER_TRANSFER,
    VL_TRANSFER_NOT_ALLOWED,
  } = ProtocolErrors;

  it('buyback test', async () => {
    const { dai, aDai, usdc, weth, aWETH, xsgd, aXSGD, pool, deployer, secondaryWallet } = testEnv;
    await dai.mint(parseEther('20000'));
    await dai.approve(pool.address, parseEther('20000'));

    await pool.deposit(dai.address, parseEther('20000'), deployer.address, 0);

    const treasuryContract = await getTreasury();
    const treasuryAddress = treasuryContract.address;
    const rnbwContract = await getRnbwMock();
    const rnbwAddress = await rnbwContract.address;
    console.log(`Rnbw Address: ${rnbwAddress}`);

    const vestingContractMock = await getDb()
      .get(`${eContractid.VestingContractMock}.${DRE.network.name}`)
      .value();
    const vestingContractAddress = vestingContractMock.address;

    const uniswapMockAddress = await treasuryContract.router();
    console.log(uniswapMockAddress);
    console.log(treasuryAddress);

    const curveFactoryMock = await getCurveFactoryMock();

    //set as collateral
    await pool.setUserUseReserveAsCollateral(dai.address, true);

    //deposit xsgd
    await xsgd.connect(secondaryWallet).mint(parseEther('50000'));

    await xsgd.connect(secondaryWallet).approve(pool.address, parseEther('50000'));
    await pool
      .connect(secondaryWallet)
      .deposit(xsgd.address, parseEther('20000'), secondaryWallet.address, 0);

    increaseTime(600);

    //borrow 2
    await pool
      .connect(secondaryWallet)
      .borrow(dai.address, parseEther('1000'), 2, 0, secondaryWallet.address);
    increaseTime(600);

    await pool
      .connect(secondaryWallet)
      .borrow(dai.address, parseEther('1000'), 2, 0, secondaryWallet.address);
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
    console.log(
      `Uniswap Contract Rnbw balance initial: ${await rnbwContract.balanceOf(uniswapMockAddress)}`
    );
    console.log(
      `Treasury Contract Rnbw balance initial: ${await rnbwContract.balanceOf(treasuryAddress)}`
    );
    console.log('Buy back rnbw ...');
    await treasuryContract.buybackRnbw([dai.address]);

    console.log(
      `Treasury Contract Rnbw balance final: ${await rnbwContract.balanceOf(treasuryAddress)}`
    );

    console.log(
      `Vesting Contract Rnbw balance initial: ${await rnbwContract.balanceOf(
        vestingContractAddress
      )}`
    );

    console.log('Send rnbw to vesting ...');

    await treasuryContract.sendToVestingContract();
    console.log(
      `Vesting Contract Rnbw balance final: ${await rnbwContract.balanceOf(vestingContractAddress)}`
    );
  });
});
