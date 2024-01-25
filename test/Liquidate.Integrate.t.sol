pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import {Vm} from 'forge-std/Vm.sol';
import 'forge-std/console.sol';

import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {ILendingPool} from '../contracts/interfaces/ILendingPool.sol';

contract IOracle {
  function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {}
}

contract LiquididateIntegrationTest is Test {
  address constant LENDINPOOL_PROXY_ADDRESS = 0xC73b2c6ab14F25e1EAd3DE75b4F6879DEde3968E;
  address constant USDC_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  string private RPC_URL = vm.envString('MAINNET_RPC_URL');
  uint256 constant FORK_BLOCK = 15432282;

  address constant ETH_USD_CHAINLINK = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
  address constant USDC_USD_CHAINLINK = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);
  }

  function testLiquidate() public {
    ILendingPool lp = ILendingPool(LENDINPOOL_PROXY_ADDRESS);

    // lp.deposit(
    //   0x0,
    //   10 * 1e18,
    //   0 // referral code
    // );

    // impersonate a user that has collateral deposited in the lending pool
    address lpUser = 0x01e198818a895f01562E0A087595E5b1C7bb8d5c;
    vm.startPrank(lpUser);

    (
      ,
      /*uint256 totalCollateralETH*/ uint256 totalDebtETH,
      uint256 availableBorrowsETH /*uint256 currentLiquidationThreshold*/ /*uint256 ltv*/ /*uint256 healthFactor*/,
      ,
      ,

    ) = lp.getUserAccountData(lpUser);
    // console.log('totalCollateralETH', totalCollateralETH);
    console.log('totalDebtETH', totalDebtETH);
    console.log('availableBorrowsETH', availableBorrowsETH);
    // console.log('currentLiquidationThreshold', currentLiquidationThreshold);
    // console.log('ltv', ltv);
    // console.log('healthFactor', healthFactor);
    (, int256 ethUsdPrice, , , ) = IOracle(ETH_USD_CHAINLINK).latestRoundData();
    (, int256 usdcUsdPrice, , , ) = IOracle(USDC_USD_CHAINLINK).latestRoundData();
    console.log('ethUsdPrice', uint256(ethUsdPrice));
    console.log('usdcUsdPrice', uint256(usdcUsdPrice));

    uint256 totalUsdcBorrows = ((availableBorrowsETH - totalDebtETH) * uint256(ethUsdPrice)) /
      uint256(usdcUsdPrice) /
      1e12;

    console.log('totalUsdcBorrows', totalUsdcBorrows);

    // address[] memory rvs = lp.getReservesList();
    // console.log('rvs 0', rvs[0]);
    // console.log('rvs 1', rvs[1]);
    // console.log('rvs 2', rvs[2]);
    // console.log('rvs 3', rvs[3]);
    // console.log('rvs 4', rvs[4]);
    // console.log('rvs 5', rvs[5]);
    // console.log('rvs 6', rvs[6]);

    // console.log('ETH/USD price', uint256(price));

    uint256 balBefore = IERC20(USDC_MAINNET).balanceOf(lpUser);
    console.log('balBefore', balBefore);

    lp.borrow(
      USDC_MAINNET,
      totalUsdcBorrows,
      2, // stablecoin borrowing
      0, // referral code
      lpUser
    );

    uint256 balAfter = IERC20(USDC_MAINNET).balanceOf(lpUser);
    console.log('balAfter', balAfter);

    (
      ,
      ,
      /*uint256 totalCollateralETH*/ uint256 availableBorrowsETH2 /*uint256 currentLiquidationThreshold*/ /*uint256 ltv*/ /*uint256 healthFactor*/,
      ,
      ,

    ) = lp.getUserAccountData(lpUser);

    console.log('availableBorrowsETH2', availableBorrowsETH2);

    // get the price for the collateral

    // manipulate the oracle to make the loan undercollateralized
    // liquidate the loan
    // check that the liquidator received the collateral

    vm.stopPrank();
  }
}
