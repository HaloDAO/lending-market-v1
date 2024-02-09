pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import {Vm} from 'forge-std/Vm.sol';
import 'forge-std/console.sol';

import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {ILendingPool} from '../contracts/interfaces/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {AaveOracle} from '../contracts/misc/AaveOracle.sol';

import {MockAggregator} from '../contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {IHaloUiPoolDataProvider} from '../contracts/misc/interfaces/IHaloUiPoolDataProvider.sol';

import {DataTypes} from '../contracts/protocol/libraries/types/DataTypes.sol';
import {IAToken} from '../contracts/interfaces/IAToken.sol';

import {LendingMarketTestHelper} from './LendingMarketTestHelper.t.sol';

contract LiquididateIntegrationTest is Test, LendingMarketTestHelper {
  string private RPC_URL = vm.envString('POLYGON_RPC_URL');
  address constant ETH_USD_CHAINLINK = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
  address constant USDC_USD_CHAINLINK = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;
  address constant AAVE_ORACLE = 0x0200889C2733bB78641126DF27A0103230452b62;
  address constant UI_DATA_PROVIDER = 0x755E39Ba1a425548fF8990A5c223C34C5ce5f8a5;
  address constant XSGD_ASSIM = 0xC933a270B922acBd72ef997614Ec46911747b799;
  address constant USDC_ASSIM = 0xfbdc1B9E50F8607E6649d92542B8c48B2fc49a1a;
  address constant ALPXSGD = 0x94d10dC16C5B47e601aa561D0e4a60950936C278;

  // address constant LENDING_POOL_ADMIN = ILendingPoolAddressesProvider.getPoolAdmin();

  // This will be the address of HLPPriceFeedOracle
  address lpOracle;

  // string memory walletLabel = "rich-guy";
  // Vm.Wallet memory WHALE_LM_LP = vm.createWallet(walletLabel);

  address constant WHALE_LM_LP = 0x1B736B89cd70Cf355d71f55E626Dc53E8D56Bc2E;
  address constant LIQUIDATOR = 0x1b736B89Cd70cf355d71f55E626Dc53e8d56Bc2A;

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);

    vm.prank(XSGD_HOLDER);
    IERC20(XSGD).transfer(me, 5_000_000 * 1e6);
    IERC20(XSGD).transfer(WHALE_LM_LP, 1_000_000 * 1e6);
    IERC20(XSGD).transfer(LIQUIDATOR, 1_000_000 * 1e6);

    vm.prank(USDC_HOLDER);
    IERC20(USDC).transfer(me, 5_000_000 * 1e6);
    IERC20(USDC).transfer(WHALE_LM_LP, 1_000_000 * 1e6);
    IERC20(USDC).transfer(LIQUIDATOR, 1_000_000 * 1e6);
  }

  /**
    ## Liquidation test
    - `Liquidate.Integrate.t.sol`
    - update to use Polygon (same like HLPPriceFeedOracle.t.sol)
    - ensure add LP Token instead of HLP
    - \_deployReserve
    - \_deployAndSetLPOracle
    - _loopSwaps for inflating/deflating price oracle rate
    - luquidate
    - profit!!!
   */

  function testLiquidateGetATokens() public {
    _printUserAccountData(me);

    uint256 liquidatorUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(LIQUIDATOR);
    uint256 liquidatedUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(me);

    console.log('[testLiquidateGetATokens] liquidatorUSDCBalBeforeLiquidation:', liquidatorUSDCBalBeforeLiquidation);

    console.log('[testLiquidateGetATokens] liquidatedUSDCBalBeforeLiquidation:', liquidatedUSDCBalBeforeLiquidation);

    _testLiquidate(1_000 * 1e18, 20, type(uint256).max, true, true, 1);

    // liquidator gets aTokens
    assertGt(IERC20(ALPXSGD).balanceOf(LIQUIDATOR), 0, 'no liquidation');
    // assertGt(liquidatedaLPXSGDBalBeforeLiquidation, IERC20(ALPXSGD).balanceOf(me));
    // console.log('atokens after liquidation - me : ', IERC20(ALPXSGD).balanceOf(me));
    // console.log('atokens after liquidation - liquidator : ', IERC20(ALPXSGD).balanceOf(LIQUIDATOR));

    // liquidator repay liquidated guy's debt to buy collateral
    assertGt(liquidatorUSDCBalBeforeLiquidation, IERC20(USDC).balanceOf(LIQUIDATOR));
  }

  function testLiquidateGetCollateralTokens() public {
    _printUserAccountData(me);

    uint256 liquidatorUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(LIQUIDATOR);
    uint256 liquidatedUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(me);

    console.log(
      '[testLiquidateGetCollateralTokens] liquidatorUSDCBalBeforeLiquidation:',
      liquidatorUSDCBalBeforeLiquidation
    );

    console.log(
      '[testLiquidateGetCollateralTokens] liquidatedUSDCBalBeforeLiquidation:',
      liquidatedUSDCBalBeforeLiquidation
    );

    uint256 liquidatorLPXSGDBalBeforeLiquidation = IERC20(LP_XSGD).balanceOf(LIQUIDATOR);
    uint256 liquidatedLPXSGDBalBeforeLiquidation = IERC20(LP_XSGD).balanceOf(me);

    console.log(
      '[testLiquidateGetCollateralTokens] liquidatorLPXSGDBalBeforeLiquidation:',
      liquidatorLPXSGDBalBeforeLiquidation
    );

    console.log(
      '[testLiquidateGetCollateralTokens] liquidatedLPXSGDBalBeforeLiquidation:',
      liquidatedLPXSGDBalBeforeLiquidation
    );

    (
      uint256 liquidator_aLPXSGDBalanceAfterLiquidation,
      uint256 liquidated_aLPXSGDBalanceAfterLiquidation,
      uint256 liquidatorUSDCBalAfterLiquidation,
      uint256 liquidatedUSDCBalAfterLiquidation
    ) = _testLiquidate(1_000 * 1e18, 10, 200 * 1e6, false, false, 1);

    // liquidator gets aTokens
    assertGt(IERC20(LP_XSGD).balanceOf(LIQUIDATOR), 0, 'no liquidation');

    // liquidator repay liquidated guy's debt to buy collateral
    assertGt(liquidatorUSDCBalBeforeLiquidation, IERC20(USDC).balanceOf(LIQUIDATOR));
  }

  // Analysis: https://docs.google.com/spreadsheets/d/1O1p9oWt4wPGyyacjOhg46jDxNxD0o_eeASSsgf-wTIk/edit?usp=sharing
  function testLiquidateLoseMoreHealthFactor() public {
    _printUserAccountData(me);

    uint256 liquidatorUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(LIQUIDATOR);
    uint256 liquidatedUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(me);

    console.log('[testLiquidateGetATokens] liquidatorUSDCBalBeforeLiquidation:', liquidatorUSDCBalBeforeLiquidation);

    console.log('[testLiquidateGetATokens] liquidatedUSDCBalBeforeLiquidation:', liquidatedUSDCBalBeforeLiquidation);

    uint256 liquidatorLPXSGDBalBeforeLiquidation = IERC20(LP_XSGD).balanceOf(LIQUIDATOR);
    uint256 liquidatedLPXSGDBalBeforeLiquidation = IERC20(LP_XSGD).balanceOf(me);

    console.log(
      '[testLiquidateGetATokens] liquidatorLPXSGDBalBeforeLiquidation:',
      liquidatorLPXSGDBalBeforeLiquidation
    );
    console.log(
      '[testLiquidateGetATokens] liquidatedLPXSGDBalBeforeLiquidation:',
      liquidatedLPXSGDBalBeforeLiquidation
    );

    _testLiquidate(1_000 * 1e18, 50, type(uint256).max, true, true, 1);

    DataTypes.ReserveData memory rdLPXSGD = LP.getReserveData(LP_XSGD);
    address aLPXSGD = rdLPXSGD.aTokenAddress;

    // console.log('[testLiquidateGetATokens] liquidatorUSDCBalAfterLiquidation:', liquidatorUSDCBalAfterLiquidation);
    // console.log('[testLiquidateGetATokens] liquidatedUSDCBalAfterLiquidation:', liquidatedUSDCBalAfterLiquidation);

    // console.log(
    //   '[testLiquidateGetATokens] liquidator_aLPXSGDBalanceAfterLiquidation:',
    //   liquidator_aLPXSGDBalanceAfterLiquidation
    // );
    // console.log(
    //   '[testLiquidateGetATokens] liquidated_aLPXSGDBalanceAfterLiquidation:',
    //   liquidated_aLPXSGDBalanceAfterLiquidation
    // );

    // liquidator gets aTokens
    assertGt(IERC20(aLPXSGD).balanceOf(LIQUIDATOR), 0, 'no liquidation');
    // @todo liquidated person lost collateral, find before balance since addition of LP asset in the reserve is inside testLiquidate
    // assertGt(liquidatedLPXSGDBalBeforeLiquidation, IERC20(aLPXSGD).balanceOf(me));

    // liquidator repay liquidated guy's debt to buy collateral
    assertGt(liquidatorUSDCBalBeforeLiquidation, IERC20(USDC).balanceOf(LIQUIDATOR));
  }

  function testFullLiquidationMultipleLiquidationCall() public {
    _printUserAccountData(me);

    uint256 liquidatorUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(LIQUIDATOR);
    uint256 liquidatedUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(me);

    console.log('[testLiquidateGetATokens] liquidatorUSDCBalBeforeLiquidation:', liquidatorUSDCBalBeforeLiquidation);
    console.log('[testLiquidateGetATokens] liquidatedUSDCBalBeforeLiquidation:', liquidatedUSDCBalBeforeLiquidation);

    uint256 liquidatorLPXSGDBalBeforeLiquidation = IERC20(LP_XSGD).balanceOf(LIQUIDATOR);
    uint256 liquidatedLPXSGDBalBeforeLiquidation = IERC20(LP_XSGD).balanceOf(me);

    console.log(
      '[testLiquidateGetATokens] liquidatorLPXSGDBalBeforeLiquidation:',
      liquidatorLPXSGDBalBeforeLiquidation
    );
    console.log(
      '[testLiquidateGetATokens] liquidatedLPXSGDBalBeforeLiquidation:',
      liquidatedLPXSGDBalBeforeLiquidation
    );

    _testLiquidate(1_000 * 1e18, 30, type(uint256).max, false, true, 3);

    DataTypes.ReserveData memory rdLPXSGD = LP.getReserveData(LP_XSGD);
    address aLPXSGD = rdLPXSGD.aTokenAddress;

    // liquidator gets aTokens and unwrapped to colalteral
    assertGt(IERC20(LP_XSGD).balanceOf(LIQUIDATOR), 0, 'no liquidation');

    // fully liquidated after 3 liquidation calls
    assertEq(IERC20(aLPXSGD).balanceOf(me), 0, 'collateral not lost');

    // liquidator repay liquidated guy's debt to buy collateral
    assertGt(liquidatorUSDCBalBeforeLiquidation, IERC20(USDC).balanceOf(LIQUIDATOR), 'usdc not liquidated');
  }

  function _testLiquidate(
    uint256 _depositLPXSGD,
    uint256 _oraclePriceDecline,
    uint256 _debtToCover,
    bool _toATokens,
    bool isLosingMoreCollateral,
    uint256 noOfLiquidationCalls
  )
    public
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    {
      (, int256 ethUsdPrice, , , ) = IOracle(ETH_USD_CHAINLINK).latestRoundData();
      (, int256 usdcUsdPrice, , , ) = IOracle(USDC_USD_CHAINLINK).latestRoundData();
      console.log('ethUsdPrice', uint256(ethUsdPrice));
      console.log('usdcUsdPrice', uint256(usdcUsdPrice));
    }

    _deployReserve();
    lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    // Set Lending market oracle for XSGD_USDC token to use newly deployed HLPOracle
    _setXsgdHLPOracle(lpOracle);
    _enableBorrowingForAddedLPAssets(LP_XSGD, true);
    _enableCollaterizationOfLPAssets(LP_XSGD);

    DataTypes.ReserveData memory rdUSDC = LP.getReserveData(USDC);
    address aUSDC = rdUSDC.aTokenAddress;

    console2.log('ETC/USD price', uint256(IHLPOracle(IHLPOracle(lpOracle).quotePriceFeed()).latestAnswer()));

    vm.startPrank(me);
    // Add liq to FX Pool to get LP_XSGD balance
    IERC20(XSGD).approve(BALANCER_VAULT, type(uint256).max);
    IERC20(USDC).approve(BALANCER_VAULT, type(uint256).max);
    vm.stopPrank();

    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);

    // Deposit collateral to use for borrowing later
    IERC20(LP_XSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);
    LP.deposit(
      LP_XSGD,
      _depositLPXSGD,
      me,
      0 // referral code
    );

    // Check how much is depositLPXSGD in HLP oracle
    // console.log('Deposited ETH (wei)', (_depositLPXSGD * uint256(IHLPOracle(lpOracle).latestAnswer())) / 1e18);
    // console.log('------ After LP XSGD Deposit --------');
    _printUserAccountData(me);

    // User sets LP_XSGD to be used as collateral in lending market pool
    LP.setUserUseReserveAsCollateral(LP_XSGD, true);

    console.log('collateral balance before borrow: ', IERC20(ALPXSGD).balanceOf(me));

    // Add an asset to the lending pool so there is some USDC we can borrow
    _putBorrowableLiquidityInLendingPool(WHALE_LM_LP, 1_000_000 * 1e6);

    {
      // Borrow up to the limit of your collateral
      uint256 usdcBorrowLimit = _borrowToLimit(me);

      console.log('usdcBorrowLimitusdcBorrowLimit:', usdcBorrowLimit);

      // lowest oracle price deviation to be full liquidated
      int256 newLPXSGDPrice = _manipulateOraclePrice(_oraclePriceDecline);

      console.log('LP XSGD Oracle Price: ', uint256(newLPXSGDPrice));

      uint256 calculatedCollateralAmount = (usdcBorrowLimit * (1 + 500)) / (uint256(newLPXSGDPrice) / 1e12);
      console.log('[testFullLiquidation] calculatedCollateralAmount', calculatedCollateralAmount);
    }

    console.log('------ After Price Manipulation --------');
    _printUserAccountData(me);

    console.log('< Printing liquidated guy account before liquidation');
    _printUserAccountData(me);
    console.log('</ Printing liquidated guy account before liquidation');

    _liquidatePosition(LIQUIDATOR, me, _toATokens, _debtToCover, isLosingMoreCollateral, noOfLiquidationCalls);

    console.log('< Printing liquidated guy account after liquidation');
    _printUserAccountData(me);
    console.log('</ Printing liquidated guy account after liquidation');

    uint256 liquidator_aLPXSGDBalanceAfterLiquidation = IERC20(ALPXSGD).balanceOf(LIQUIDATOR);
    uint256 liquidated_aLPXSGDBalanceAfterLiquidation = IERC20(ALPXSGD).balanceOf(me);

    uint256 liquidatorUSDCBalAfterLiquidation = IERC20(USDC).balanceOf(LIQUIDATOR);
    uint256 liquidatedUSDCBalAfterLiquidation = IERC20(USDC).balanceOf(me);

    console.log('Balance after: ', liquidator_aLPXSGDBalanceAfterLiquidation);

    return (
      liquidator_aLPXSGDBalanceAfterLiquidation,
      liquidated_aLPXSGDBalanceAfterLiquidation,
      liquidatorUSDCBalAfterLiquidation,
      liquidatedUSDCBalAfterLiquidation
    );
  }

  function _putBorrowableLiquidityInLendingPool(address _donor, uint256 _amount) private {
    vm.startPrank(_donor);

    IERC20(XSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);
    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);

    LP.deposit(
      XSGD,
      _amount,
      _donor,
      0 // referral code
    );

    LP.deposit(
      USDC,
      _amount,
      _donor,
      0 // referral code
    );

    vm.stopPrank();
  }

  function _printLiqIndex(address _asset) private {
    DataTypes.ReserveData memory rd = LP.getReserveData(_asset);
    console.log('liquidityIndex', rd.liquidityIndex);
  }

  function _repayLoan(address _user) private {
    (IHaloUiPoolDataProvider.AggregatedReserveData[] memory rd1, ) = IHaloUiPoolDataProvider(UI_DATA_PROVIDER)
      .getReservesData(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER));
    console.log('liqIndex before\t', rd1[1].liquidityIndex);

    vm.warp(block.timestamp + 31536000);

    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);
    LP.repay(USDC, 50_000 * 1e6, 2, _user);

    (IHaloUiPoolDataProvider.AggregatedReserveData[] memory rd2, ) = IHaloUiPoolDataProvider(UI_DATA_PROVIDER)
      .getReservesData(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER));

    console.log('liqIndex after\t', rd2[1].liquidityIndex);
  }

  function _depositWithdraw() private {
    // @TODO tbd deposit 50k USDC, receive 50K (+1 wei) aUSDC, withdraw 50K aUSDC, receive 50K USDC (+1 wei)
    address me = address(this);
    uint256 balBefore = IERC20(USDC).balanceOf(me);
    console.log('block.timestamp', block.timestamp);
    _printLiqIndex(USDC);
    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);
    LP.deposit(
      USDC,
      50_000 * 1e6,
      me,
      0 // referral code
    );

    // print amount of aTokens received
    DataTypes.ReserveData memory rd = LP.getReserveData(USDC);
    address aToken = rd.aTokenAddress;

    console.log('aToken', IERC20(aToken).balanceOf(me));

    LP.withdraw(USDC, IERC20(aToken).balanceOf(me), me);

    console.log('block.timestamp', block.timestamp);
    _printLiqIndex(USDC);

    console.log('USDC Received After Deposit/Withdraw', IERC20(USDC).balanceOf(me) - balBefore);
  }

  function _setXsgdHLPOracle(address _oracle) private {
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();

    address[] memory assets = new address[](1);
    assets[0] = LP_XSGD;
    address[] memory sources = new address[](1);
    sources[0] = lpOracle;

    address oracleOwner = AaveOracle(aaveOracle).owner();
    vm.prank(oracleOwner);
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    console2.log('[_setXsgdHLPOracle] Done setting price oracle for XSGD_USDC collateral', lpOracle);
  }

  function _borrowToLimit(address _user) private returns (uint256) {
    (
      ,
      ,
      /*uint256 totalCollateralETH*/
      uint256 availableBorrowsETH,
      ,
      ,

    ) = LP.getUserAccountData(_user);

    (, int256 ethUsdPrice, , , ) = IOracle(ETH_USD_CHAINLINK).latestRoundData();
    (, int256 usdcUsdPrice, , , ) = IOracle(USDC_USD_CHAINLINK).latestRoundData();

    vm.startPrank(_user);
    // @note might be rounding off issue?
    // uint256 totalUsdcBorrows = (((availableBorrowsETH - totalDebtETH) * (uint256(ethUsdPrice))) /
    //   uint256(usdcUsdPrice)) / 1e12;
    uint256 totalUsdcBorrows = (((availableBorrowsETH * uint256(ethUsdPrice)) / uint256(usdcUsdPrice)) / 1e18);
    // console.log('[_borrowToLimit] totalUsdcBorrows:', totalUsdcBorrows);
    // console.log('[_borrowToLimit] totalDebtETH:', totalDebtETH);
    // console.log('[_borrowToLimit] ltv:', ltv);

    // uint256 balBefore = IERC20(USDC).balanceOf(_user);
    // console.log('[_borrowToLimit] usdc balance before borrow', balBefore);

    uint256 usdcBorrowLimit = (totalUsdcBorrows - 5) * 1e6;
    console.log('[_borrowToLimit] usdcBorrowLimit:', usdcBorrowLimit);

    LP.borrow(
      USDC,
      usdcBorrowLimit,
      2, // stablecoin borrowing
      0, // referral code
      _user
    );

    uint256 balAfter = IERC20(USDC).balanceOf(_user);
    console.log('[_borrowToLimit] usdc balance after borrow', balAfter);

    vm.stopPrank();

    return usdcBorrowLimit;
  }

  function _getLendingPoolReserveConfig()
    private
    view
    returns (
      // address _asset
      DataTypes.ReserveConfigurationMap memory
    )
  {
    // address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
    (IHaloUiPoolDataProvider.AggregatedReserveData[] memory rd, ) = IHaloUiPoolDataProvider(UI_DATA_PROVIDER)
      .getReservesData(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER));

    for (uint32 i = 0; i < rd.length; i++) {
      if (rd[i].underlyingAsset == LP_XSGD) {
        console.log('rd[i].underlyingAsset', rd[i].underlyingAsset);
        console.log('rd[i].baseLTVasCollateral', rd[i].baseLTVasCollateral);
        console.log('rd[i].reserveFactor', rd[i].reserveFactor);
        console.log('rd[i].usageAsCollateralEnabled', rd[i].usageAsCollateralEnabled);
      }
    }

    // address[] memory reservesList = IHaloUiPoolDataProvider(UI_DATA_PROVIDER).getReservesList(
    //   ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER)
    // );

    // for (uint32 i = 0; i < reservesList.length; i++) {
    //   // if (reservesList[i] == _asset) {
    //   //   return IHaloUiPoolDataProvider(UI_DATA_PROVIDER).getReserveConfigurationData(
    //   //     ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER),
    //   //     reservesList[i]
    //   //   );
    //   // }
    //   console.log('reservesList[i]', reservesList[i]);
    // }
  }

  function _enableBorrowingForAddedLPAssets(address _asset, bool doEnable) private {
    address lendingPoolConfigurator = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER)
      .getLendingPoolConfigurator();

    address poolAdmin = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPoolAdmin();
    // console.log('poolAdmin:', poolAdmin);
    vm.startPrank(poolAdmin);
    ILendingPoolConfigurator(lendingPoolConfigurator).enableBorrowingOnReserve(_asset, doEnable);
    vm.stopPrank();
  }

  function _enableCollaterizationOfLPAssets(address _asset) private {
    address lendingPoolConfigurator = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER)
      .getLendingPoolConfigurator();

    address poolAdmin = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPoolAdmin();
    vm.startPrank(poolAdmin);

    uint256 ltv = 8000;
    uint256 liquidationThreshold = 8500;
    uint256 LIQUIDATION_BONUS = 10500;
    ILendingPoolConfigurator(lendingPoolConfigurator).configureReserveAsCollateral(
      _asset,
      ltv,
      liquidationThreshold,
      LIQUIDATION_BONUS
    );
    vm.stopPrank();
  }

  function _printUserAccountData(address _user) private {
    (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    ) = LP.getUserAccountData(_user);
    // console.log('totalCollateralETH', totalCollateralETH);
    console.log('[_printUserAccountData] totalCollateralETH:', totalCollateralETH);
    console.log('[_printUserAccountData] totalDebtETH', totalDebtETH);
    console.log('[_printUserAccountData] availableBorrowsETH', availableBorrowsETH);
    console.log('[_printUserAccountData] currentLiquidationThreshold', currentLiquidationThreshold);
    console.log('[_printUserAccountData] healthFactor (divided by totalDebt (possibly 0))', healthFactor);
    // console.log('currentLiquidationThreshold', currentLiquidationThreshold);
    // console.log('ltv', ltv);
  }

  function _loopLiquidationCall(
    uint256 noOfLiquidationCalls,
    bool receiveAToken,
    address liquidatedGuy
  ) private {
    for (uint256 j = 0; j < noOfLiquidationCalls; j++) {
      LP.liquidationCall(LP_XSGD, USDC, liquidatedGuy, type(uint256).max, receiveAToken);
    }
  }

  function _liquidatePosition(
    address liquidator,
    address liquidatedGuy,
    bool isAtokens,
    uint256 debtToCover,
    bool isLosingMoreCollateral,
    uint256 noOfLiquidationCalls
  ) private {
    (
      uint256 totalCollateralETHBeforeLiquidation,
      uint256 totalDebtETHBeforeLiquidation,
      ,
      ,
      ,
      uint256 healthFactorBeforeLiquidation
    ) = LP.getUserAccountData(me);

    DataTypes.ReserveData memory rdUSDC = LP.getReserveData(USDC);
    DataTypes.ReserveData memory rdLPXSGD = LP.getReserveData(LP_XSGD);
    // we only have variable rates
    uint256 liquidatedGuyVariableDebtTokensBeforeLiquidation = IERC20(rdUSDC.variableDebtTokenAddress).balanceOf(me);
    uint256 liquidatedGuyCollateralBeforeLiquidation = IERC20(rdLPXSGD.aTokenAddress).balanceOf(me);

    console.log(IERC20(rdLPXSGD.aTokenAddress).balanceOf(me));

    vm.startPrank(liquidator);

    uint256 liquidatorLPXGDBefore = IERC20(LP_XSGD).balanceOf(liquidator);
    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);

    if (isAtokens) {
      // get aTokens
      _loopLiquidationCall(noOfLiquidationCalls, true, liquidatedGuy);
    } else {
      _loopLiquidationCall(noOfLiquidationCalls, false, liquidatedGuy);
    }

    (
      uint256 totalCollateralETHAfterLiquidation,
      uint256 totalDebtETHAfterLiquidation,
      ,
      ,
      ,
      uint256 healthFactorAfterLiquidation
    ) = LP.getUserAccountData(me);

    // burning of debt tokens
    assertGt(
      liquidatedGuyVariableDebtTokensBeforeLiquidation,
      IERC20(rdUSDC.variableDebtTokenAddress).balanceOf(me),
      'tokens not burned'
    );

    // collateral loss
    assertGt(
      liquidatedGuyCollateralBeforeLiquidation,
      IERC20(rdLPXSGD.aTokenAddress).balanceOf(me),
      'no collateral loss'
    );

    // improve health factor
    isLosingMoreCollateral
      ? assertGt(healthFactorBeforeLiquidation, healthFactorAfterLiquidation, 'health factor condition not met')
      : assertGt(healthFactorAfterLiquidation, healthFactorBeforeLiquidation, 'health factor condition not met');

    assertGt(
      totalCollateralETHBeforeLiquidation,
      totalCollateralETHAfterLiquidation,
      'total collateral not liquidated'
    );
    // console.log(currentLiquidationThreshold, totalCollateralETHAfterLiquidation, totalDebtETHAfterLiquidation);
    // total liquidatable asset is 50%
    // >50% of the debt is only liquidated per liquidation call
    noOfLiquidationCalls == 1
      ? assertGe(
        50,
        ((totalDebtETHBeforeLiquidation - totalDebtETHAfterLiquidation) * 100) / totalDebtETHBeforeLiquidation,
        'total debt liquidated is more than 50%'
      )
      : assertLe(
        50,
        ((totalDebtETHBeforeLiquidation - totalDebtETHAfterLiquidation) * 100) / totalDebtETHBeforeLiquidation
      );

    vm.stopPrank();
  }

  function _manipulateOraclePrice(uint256 priceLossPercentage) private returns (int256) {
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();

    address oracleOwner = AaveOracle(aaveOracle).owner();
    uint256 _lpCollateralPrice = AaveOracle(aaveOracle).getAssetPrice(LP_XSGD);

    console.log('_lpCollateralPrice', _lpCollateralPrice);
    console.log('_debtPrice', AaveOracle(aaveOracle).getAssetPrice(USDC));

    // address assSource = AaveOracle(aaveOracle).getSourceOfAsset(LP_XSGD);
    // console.log('assSource', assSource);
    // console.log('fallbackOracle', AaveOracle(aaveOracle).getFallbackOracle());
    // console.log('BASE_CURRENCY', AaveOracle(aaveOracle).BASE_CURRENCY());

    int256 newPrice = int256(_lpCollateralPrice - (_lpCollateralPrice * priceLossPercentage) / 100);

    {
      address[] memory assets = new address[](1);
      assets[0] = LP_XSGD;
      address[] memory sources = new address[](1);
      sources[0] = address(new MockAggregator(newPrice));
      vm.prank(oracleOwner);
      AaveOracle(aaveOracle).setAssetSources(assets, sources);
    }
    console2.log('newPrice after manip: ', newPrice);
    return newPrice;
  }
}

interface IOracle {
  function latestRoundData()
    external
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    );
}

interface IUsdcToken {
  function mint(address to, uint256 amount) external;

  function configureMinter(address minter, uint256 minterAllowedAmount) external;
}

interface IHLPOracle {
  function baseContract() external view returns (address);

  function quotePriceFeed() external view returns (address);

  function latestAnswer() external view returns (int256);
}

interface IFXPool {
  struct Assimilator {
    address addr;
    uint8 ix;
  }

  function getPoolId() external view returns (bytes32);

  function viewParameters()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  // returns(totalLiquidityInNumeraire, individual liquidity)
  function liquidity() external view returns (uint256, uint256[] memory);

  function totalSupply() external view returns (uint256);

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);
}

interface ILendingPoolConfigurator {
  function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled) external;

  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;
}
