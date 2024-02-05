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

  // @TODO:
  // refactor to make code reusable?
  // test for liquidation bonus: check how much liquidation bonus it gets in actual and check calculation based on known constants from the
  // lending market confid

  // function testLiquidateGetATokens() public {
  //   _printUserAccountData(me);
  //   uint256 depositLPXSGD = 1_000 * 1e18;

  //   {
  //     (, int256 ethUsdPrice, , , ) = IOracle(ETH_USD_CHAINLINK).latestRoundData();
  //     (, int256 usdcUsdPrice, , , ) = IOracle(USDC_USD_CHAINLINK).latestRoundData();
  //     console.log('ethUsdPrice', uint256(ethUsdPrice));
  //     console.log('usdcUsdPrice', uint256(usdcUsdPrice));
  //   }

  //   _deployReserve();
  //   lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

  //   // Set Lending market oracle for XSGD_USDC token to use newly deployed HLPOracle
  //   _setXsgdHLPOracle(lpOracle);
  //   _enableBorrowingForAddedLPAssets(LP_XSGD, true);
  //   _enableCollaterizationOfLPAssets(LP_XSGD);

  //   DataTypes.ReserveData memory rdUSDC = LP.getReserveData(USDC);
  //   address aUSDC = rdUSDC.aTokenAddress;

  //   DataTypes.ReserveData memory rdLPXSGD = LP.getReserveData(LP_XSGD);
  //   address aLPXSGD = rdLPXSGD.aTokenAddress;

  //   int256 lpPrice = IHLPOracle(lpOracle).latestAnswer();
  //   console2.log('ETC/USD price', uint256(IHLPOracle(IHLPOracle(lpOracle).quotePriceFeed()).latestAnswer()));

  //   vm.startPrank(me);
  //   // Add liq to FX Pool to get LP_XSGD balance
  //   IERC20(XSGD).approve(BALANCER_VAULT, type(uint).max);
  //   IERC20(USDC).approve(BALANCER_VAULT, type(uint).max);
  //   vm.stopPrank();

  //   _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);

  //   console.log('LP_XSGD balance after add liq', IERC20(LP_XSGD).balanceOf(me) / 1e18);
  //   console.log('Total LP XSGD before deposit:', IERC20(LP_XSGD).balanceOf(me) / 1e18);

  //   // Deposit collateral to use for borrowing later
  //   IERC20(LP_XSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);
  //   LP.deposit(
  //     LP_XSGD,
  //     depositLPXSGD,
  //     me,
  //     0 // referral code
  //   );

  //   // Check how much is depositLPXSGD in HLP oracle
  //   console.log('Deposited ETH (wei)', (depositLPXSGD * uint256(IHLPOracle(lpOracle).latestAnswer())) / 1e18);
  //   console.log('Total LP XSGD after deposit:', IERC20(LP_XSGD).balanceOf(me) / 1e18);
  //   console.log('------ After LP XSGD Deposit --------');
  //   _printUserAccountData(me);

  //   // Calculate equivalent USDC amount of LP_XSGD

  //   // User sets LP_XSGD to be used as collateral in lending market pool
  //   LP.setUserUseReserveAsCollateral(LP_XSGD, true);

  //   // IERC20(aLPXSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max); // not needed

  //   // Add an asset to the lending pool so there is some USDC we can borrow
  //   _putBorrowableLiquidityInLendingPool(WHALE_LM_LP, 1_000_000 * 1e6);

  //   console.log('aLPXSGD', IERC20(aLPXSGD).balanceOf(me));

  //   /**
  //     1. Check borrowing enabled
  //     2. Check all reserves tapos check kung tama yung aTokenAddresss ()
  //     3. IAaveOracle(aaveOracle).getAssetPrice() if has price (yes)
  //    */

  //   address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
  //   console.log('LP XSGD Aave asset price', IAaveOracle(aaveOracle).getAssetPrice(LP_XSGD));

  //   // _getLendingPoolReserveConfig();

  //   console.log('---- User Lending Market Balance After Deposit Before Borrow ----');
  //   // _printUserAccountData(me);
  //   // Enable borrowing for added LP assets
  //   console.log('--- Enabled borrowing for LP XSGD ---');

  //   // Borrow up to the limit of your collateral
  //   {
  //     _borrowToLimit(me);
  //   }

  //   IHaloUiPoolDataProvider.UserReserveData[] memory userReserves = IHaloUiPoolDataProvider(UI_DATA_PROVIDER)
  //     .getUserReservesData(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER), me);

  //   // manipulate the oracle to make the loan undercollateralized
  //   {
  //     _manipulateOraclePrice(50);
  //   }

  //   console.log('------ After Price Manipulation --------');
  //   _printUserAccountData(me);
  //   console.log('------ Before Liquidation --------');

  //   uint256 liquidator_aLPXSGDBalanceBeforeLiquidation = IERC20(aLPXSGD).balanceOf(LIQUIDATOR);
  //   uint256 liquidated_aLPXSGDBalanceBeforeLiquidation = IERC20(aLPXSGD).balanceOf(me);

  //   console.log(
  //     '[testLiquidateGetATokens] liquidator_aLPXSGDBalanceBeforeLiquidation:',
  //     liquidator_aLPXSGDBalanceBeforeLiquidation
  //   );
  //   console.log(
  //     '[testLiquidateGetATokens] liquidated_aLPXSGDBalanceBeforeLiquidation:',
  //     liquidated_aLPXSGDBalanceBeforeLiquidation
  //   );

  //   _liquidatePosition(LIQUIDATOR, me, true);

  //   {
  //     uint256 liquidator_aLPXSGDBalanceAfterLiquidation = IERC20(aLPXSGD).balanceOf(LIQUIDATOR);

  //     console.log(
  //       '[testLiquidateGetATokens] liquidator_aLPXSGDBalanceAfterLiquidation:',
  //       liquidator_aLPXSGDBalanceAfterLiquidation
  //     );
  //   }

  //   uint256 liquidated_aLPXSGDBalanceAfterLiquidation = IERC20(aLPXSGD).balanceOf(me);

  //   console.log(
  //     '[testLiquidateGetATokens] liquidated_aLPXSGDBalanceAfterLiquidation:',
  //     liquidated_aLPXSGDBalanceAfterLiquidation
  //   );

  //   // liquidated user has less aLPXSGD after liquidation
  //   assertGt(liquidated_aLPXSGDBalanceBeforeLiquidation, IERC20(aLPXSGD).balanceOf(me));
  //   // liquidator gets the liquidated collateral + collateral bonus
  //   // @todo: check how to compute for liquidated collateral + collateral bonus in aTokens
  //   assertGt(IERC20(aLPXSGD).balanceOf(LIQUIDATOR), liquidator_aLPXSGDBalanceBeforeLiquidation);
  // }

  // function testLiquidateGetCollateralTokens() public {
  //   _printUserAccountData(me);
  //   uint256 depositLPXSGD = 1_000 * 1e18;

  //   {
  //     (, int256 ethUsdPrice, , , ) = IOracle(ETH_USD_CHAINLINK).latestRoundData();
  //     (, int256 usdcUsdPrice, , , ) = IOracle(USDC_USD_CHAINLINK).latestRoundData();
  //     console.log('ethUsdPrice', uint256(ethUsdPrice));
  //     console.log('usdcUsdPrice', uint256(usdcUsdPrice));
  //   }

  //   _deployReserve();
  //   lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

  //   // Set Lending market oracle for XSGD_USDC token to use newly deployed HLPOracle
  //   _setXsgdHLPOracle(lpOracle);
  //   _enableBorrowingForAddedLPAssets(LP_XSGD, true);
  //   _enableCollaterizationOfLPAssets(LP_XSGD);

  //   DataTypes.ReserveData memory rdUSDC = LP.getReserveData(USDC);
  //   address aUSDC = rdUSDC.aTokenAddress;

  //   DataTypes.ReserveData memory rdLPXSGD = LP.getReserveData(LP_XSGD);
  //   address aLPXSGD = rdLPXSGD.aTokenAddress;

  //   int256 lpPrice = IHLPOracle(lpOracle).latestAnswer();
  //   console2.log('ETC/USD price', uint256(IHLPOracle(IHLPOracle(lpOracle).quotePriceFeed()).latestAnswer()));

  //   vm.startPrank(me);
  //   // Add liq to FX Pool to get LP_XSGD balance
  //   IERC20(XSGD).approve(BALANCER_VAULT, type(uint).max);
  //   IERC20(USDC).approve(BALANCER_VAULT, type(uint).max);
  //   vm.stopPrank();

  //   _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);

  //   console.log('LP_XSGD balance after add liq', IERC20(LP_XSGD).balanceOf(me) / 1e18);
  //   console.log('Total LP XSGD before deposit:', IERC20(LP_XSGD).balanceOf(me) / 1e18);

  //   // Deposit collateral to use for borrowing later
  //   IERC20(LP_XSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);
  //   LP.deposit(
  //     LP_XSGD,
  //     depositLPXSGD,
  //     me,
  //     0 // referral code
  //   );

  //   // Check how much is depositLPXSGD in HLP oracle
  //   console.log('Deposited ETH (wei)', (depositLPXSGD * uint256(IHLPOracle(lpOracle).latestAnswer())) / 1e18);
  //   console.log('Total LP XSGD after deposit:', IERC20(LP_XSGD).balanceOf(me) / 1e18);
  //   console.log('------ After LP XSGD Deposit --------');
  //   _printUserAccountData(me);

  //   // Calculate equivalent USDC amount of LP_XSGD

  //   // User sets LP_XSGD to be used as collateral in lending market pool
  //   LP.setUserUseReserveAsCollateral(LP_XSGD, true);

  //   // IERC20(aLPXSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max); // not needed

  //   // Add an asset to the lending pool so there is some USDC we can borrow
  //   _putBorrowableLiquidityInLendingPool(WHALE_LM_LP, 1_000_000 * 1e6);

  //   console.log('aLPXSGD', IERC20(aLPXSGD).balanceOf(me));

  //   address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
  //   console.log('LP XSGD Aave asset price', IAaveOracle(aaveOracle).getAssetPrice(LP_XSGD));

  //   // _getLendingPoolReserveConfig();

  //   console.log('---- User Lending Market Balance After Deposit Before Borrow ----');
  //   // _printUserAccountData(me);
  //   // Enable borrowing for added LP assets
  //   console.log('--- Enabled borrowing for LP XSGD ---');

  //   // Borrow up to the limit of your collateral
  //   {
  //     _borrowToLimit(me);
  //   }

  //   IHaloUiPoolDataProvider.UserReserveData[] memory userReserves = IHaloUiPoolDataProvider(UI_DATA_PROVIDER)
  //     .getUserReservesData(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER), me);

  //   // manipulate the oracle to make the loan undercollateralized
  //   {
  //     _manipulateOraclePrice(50);
  //   }

  //   console.log('------ After Price Manipulation --------');
  //   _printUserAccountData(me);
  //   console.log('------ Before Liquidation --------');

  //   uint256 liquidator_LPXSGDBalanceBeforeLiquidation = IERC20(LP_XSGD).balanceOf(LIQUIDATOR);

  //   uint256 liquidated_aLPXSGDBalanceBeforeLiquidation = IERC20(aLPXSGD).balanceOf(me);

  //   console.log(
  //     '[testLiquidateGetCollateralTokens] liquidator_LPXSGDBalanceBeforeLiquidation:',
  //     liquidator_LPXSGDBalanceBeforeLiquidation
  //   );

  //   console.log(
  //     '[testLiquidateGetCollateralTokens] liquidated_aLPXSGDBalanceBeforeLiquidation:',
  //     liquidated_aLPXSGDBalanceBeforeLiquidation
  //   );

  //   {
  //     uint256 liquidatorXSGDBalBeforeLiquidation = IERC20(XSGD).balanceOf(LIQUIDATOR);
  //     uint256 liquidatorUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(LIQUIDATOR);

  //     console.log(
  //       '[testLiquidateGetCollateralTokens] liquidator before liquidation IERC20(XSGD).balanceOf(LIQUIDATOR):',
  //       liquidatorXSGDBalBeforeLiquidation
  //     );
  //     console.log(
  //       '[testLiquidateGetCollateralTokens] liquidator before liquidation IERC20(USDC).balanceOf(LIQUIDATOR):',
  //       liquidatorUSDCBalBeforeLiquidation
  //     );
  //   }

  //   _liquidatePosition(LIQUIDATOR, me, false);

  //   // uint256 liquidator_LPXSGDBalanceAfterLiquidation = IERC20(LP_XSGD).balanceOf(LIQUIDATOR);
  //   // uint256 liquidated_aLPXSGDBalanceAfterLiquidation = IERC20(aLPXSGD).balanceOf(me);

  //   // console.log(
  //   //   '[testLiquidateGetCollateralTokens] liquidator after liquidation IERC20(XSGD).balanceOf(LIQUIDATOR):',
  //   //   IERC20(XSGD).balanceOf(LIQUIDATOR)
  //   // );
  //   // console.log(
  //   //   '[testLiquidateGetCollateralTokens] liquidator after liquidation IERC20(USDC).balanceOf(LIQUIDATOR):',
  //   //   IERC20(USDC).balanceOf(LIQUIDATOR)
  //   // );

  //   // console.log(
  //   //   '[testLiquidateGetCollateralTokens] liquidator_LPXSGDBalanceAfterLiquidation:',
  //   //   liquidator_LPXSGDBalanceAfterLiquidation
  //   // );
  //   // console.log(
  //   //   '[testLiquidateGetCollateralTokens] liquidated_aLPXSGDBalanceAfterLiquidation:',
  //   //   liquidated_aLPXSGDBalanceAfterLiquidation
  //   // );

  //   // liquidated user has less aLPXSGD after liquidation
  //   assertGt(liquidated_aLPXSGDBalanceBeforeLiquidation, IERC20(aLPXSGD).balanceOf(me));
  //   // liquidator gets the liquidated collateral + collateral bonus in collateral value
  //   // @todo: check how to compute for liquidated collateral + collateral bonus
  //   assertGt(IERC20(LP_XSGD).balanceOf(LIQUIDATOR), liquidator_LPXSGDBalanceBeforeLiquidation);
  // }

  function testFullLiquidation() public {
    _printUserAccountData(me);
    uint256 depositLPXSGD = 1_000 * 1e18;

    uint256 liquidatorUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(LIQUIDATOR);
    uint256 liquidatedUSDCBalBeforeLiquidation = IERC20(USDC).balanceOf(me);

    console.log('[testFullLiquidation] liquidatorUSDCBalBeforeLiquidation:', liquidatorUSDCBalBeforeLiquidation);

    console.log('[testFullLiquidation] liquidatedUSDCBalBeforeLiquidation:', liquidatedUSDCBalBeforeLiquidation);

    uint256 liquidatorLPXSGDBalBeforeLiquidation = IERC20(LP_XSGD).balanceOf(LIQUIDATOR);
    uint256 liquidatedLPXSGDBalBeforeLiquidation = IERC20(LP_XSGD).balanceOf(me);

    console.log('[testFullLiquidation] liquidatorLPXSGDBalBeforeLiquidation:', liquidatorLPXSGDBalBeforeLiquidation);

    console.log('[testFullLiquidation] liquidatedLPXSGDBalBeforeLiquidation:', liquidatedLPXSGDBalBeforeLiquidation);

    (
      uint256 liquidator_aLPXSGDBalanceAfterLiquidation,
      uint256 liquidated_aLPXSGDBalanceAfterLiquidation,
      uint256 liquidatorUSDCBalAfterLiquidation,
      uint256 liquidatedUSDCBalAfterLiquidation
    ) = _testLiquidate(depositLPXSGD, 59, 200 * 1e6, true);

    console.log('[testFullLiquidation] liquidatorUSDCBalAfterLiquidation:', liquidatorUSDCBalAfterLiquidation);

    console.log('[testFullLiquidation] liquidatedUSDCBalAfterLiquidation:', liquidatedUSDCBalAfterLiquidation);

    console.log(
      '[testFullLiquidation] liquidator_aLPXSGDBalanceAfterLiquidation:',
      liquidator_aLPXSGDBalanceAfterLiquidation
    );
    console.log(
      '[testFullLiquidation] liquidated_aLPXSGDBalanceAfterLiquidation:',
      liquidated_aLPXSGDBalanceAfterLiquidation
    );

    // All aTokens be transferred to the liquidator upon full liquidation
    // assertEq(IERC20(aLPXSGD).balanceOf(me), 0);
    // assertEq(IERC20(aLPXSGD).balanceOf(LIQUIDATOR), liquidated_aLPXSGDBalanceBeforeLiquidation);
  }

  function _testLiquidate(
    uint256 _depositLPXSGD,
    uint256 _oraclePriceDecline,
    uint256 _debtToCover,
    bool _toATokens
  ) public returns (uint256, uint256, uint256, uint256) {
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

    DataTypes.ReserveData memory rdLPXSGD = LP.getReserveData(LP_XSGD);
    address aLPXSGD = rdLPXSGD.aTokenAddress;

    int256 lpPrice = IHLPOracle(lpOracle).latestAnswer();
    console2.log('ETC/USD price', uint256(IHLPOracle(IHLPOracle(lpOracle).quotePriceFeed()).latestAnswer()));

    vm.startPrank(me);
    // Add liq to FX Pool to get LP_XSGD balance
    IERC20(XSGD).approve(BALANCER_VAULT, type(uint).max);
    IERC20(USDC).approve(BALANCER_VAULT, type(uint).max);
    vm.stopPrank();

    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);


    // Deposit collateral to use for borrowing later
    IERC20(LP_XSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);
    LP.deposit(
      LP_XSGD,
      _depositLPXSGD,
      me,
      0 // referral code
    );

    // Check how much is depositLPXSGD in HLP oracle
    console.log('Deposited ETH (wei)', (_depositLPXSGD * uint256(IHLPOracle(lpOracle).latestAnswer())) / 1e18);
    // console.log('------ After LP XSGD Deposit --------');
    _printUserAccountData(me);


    // User sets LP_XSGD to be used as collateral in lending market pool
    LP.setUserUseReserveAsCollateral(LP_XSGD, true);

    // Add an asset to the lending pool so there is some USDC we can borrow
    _putBorrowableLiquidityInLendingPool(WHALE_LM_LP, 1_000_000 * 1e6);

    // address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
    // console.log('LP XSGD Aave asset price', IAaveOracle(aaveOracle).getAssetPrice(LP_XSGD));

    // _getLendingPoolReserveConfig();

    // IHaloUiPoolDataProvider.UserReserveData[] memory userReserves = IHaloUiPoolDataProvider(UI_DATA_PROVIDER)
    //   .getUserReservesData(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER), me);

    {
      // Borrow up to the limit of your collateral
      uint256 usdcBorrowLimit = _borrowToLimit(me);

      console.log('usdcBorrowLimitusdcBorrowLimit:', usdcBorrowLimit);

      // lowest oracle price deviation to be full liquidated
      int256 newLPXSGDPrice = _manipulateOraclePrice(_oraclePriceDecline);
      // TODO: What is pool ratio at this time?
      console.log('LP XSGD Oracle Price: ', uint256(newLPXSGDPrice));

      uint256 calculatedCollateralAmount = (usdcBorrowLimit * (1 + 500)) / (uint256(newLPXSGDPrice) / 1e12);
      console.log('[testFullLiquidation] calculatedCollateralAmount', calculatedCollateralAmount);
    }

    console.log('------ After Price Manipulation --------');
    _printUserAccountData(me);

    console.log('< Printing liquidated guy account before liquidation');
    _printUserAccountData(me);
    console.log('</ Printing liquidated guy account before liquidation');

    _liquidatePosition(LIQUIDATOR, me, _toATokens, _debtToCover);

    console.log('< Printing liquidated guy account after liquidation');
    _printUserAccountData(me);
    console.log('</ Printing liquidated guy account after liquidation');

    uint256 liquidator_aLPXSGDBalanceAfterLiquidation = IERC20(aLPXSGD).balanceOf(LIQUIDATOR);
    uint256 liquidated_aLPXSGDBalanceAfterLiquidation = IERC20(aLPXSGD).balanceOf(me);

    uint256 liquidatorUSDCBalAfterLiquidation = IERC20(USDC).balanceOf(LIQUIDATOR);
    uint256 liquidatedUSDCBalAfterLiquidation = IERC20(USDC).balanceOf(me);

    return (
      liquidator_aLPXSGDBalanceAfterLiquidation,
      liquidated_aLPXSGDBalanceAfterLiquidation,
      liquidatorUSDCBalAfterLiquidation,
      liquidatedUSDCBalAfterLiquidation
    );
  }

  function _putBorrowableLiquidityInLendingPool(address _donor, uint256 _amount) private {
    vm.startPrank(_donor);

    IERC20(XSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);
    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);

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

    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);
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
    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);
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
    // Is this still needed if we are deploying a new lpOracle?
    // I think yes to point the newly deployed lpOracle to the correct HLP
    // _setXsgdHLPOracle(lpOracle);
    // (
    //   ,
    //   /*uint256 totalCollateralETH*/
    //   uint256 totalDebtETH,
    //   uint256 availableBorrowsETH,
    //   uint256 currentLiquidationThreshold,
    //   uint256 ltv,
    //   uint256 healthFactor
    // ) = LP.getUserAccountData(_user);
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

    // (
    //   ,
    //   ,
    //   /*uint256 totalCollateralETH*/ uint256 availableBorrowsETH2,
    //   uint256 currentLiquidationThreshold2 /*uint256 ltv*/,
    //   ,
    //   uint256 healthFactor2
    // ) = LP.getUserAccountData(_user);

    // console.log('[_borrowToLimit] availableBorrowsETH2', availableBorrowsETH2);
    // console.log('[_borrowToLimit] after borrow health factor: ', healthFactor2);

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

    // TODO: Left here jan 31
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

  function _liquidatePosition(address liquidator, address liquidatedGuy, bool isAtokens, uint256 debtToCover) private {
    vm.startPrank(liquidator);

    uint256 liquidatorLPXGDBefore = IERC20(LP_XSGD).balanceOf(liquidator);
    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);

    if (isAtokens) {
      // get aTokens
      LP.liquidationCall(LP_XSGD, USDC, liquidatedGuy, debtToCover, true);
      // LP.withdraw(LP_XSGD, type(uint).max, liquidator);
    } else {
      LP.liquidationCall(LP_XSGD, USDC, liquidatedGuy, debtToCover, false);
    }
    vm.stopPrank();
  }

  function _liquidateUsingAddedLPAsset() private {}

  function _manipulateOraclePrice(uint256 priceLossPercentage) private returns (int256) {
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();

    address oracleOwner = AaveOracle(aaveOracle).owner();
    uint256 _price = AaveOracle(aaveOracle).getAssetPrice(LP_XSGD);

    console.log('price', _price);

    // address assSource = AaveOracle(aaveOracle).getSourceOfAsset(LP_XSGD);
    // console.log('assSource', assSource);
    // console.log('fallbackOracle', AaveOracle(aaveOracle).getFallbackOracle());
    // console.log('BASE_CURRENCY', AaveOracle(aaveOracle).BASE_CURRENCY());

    int256 newPrice = int256(_price - (_price * priceLossPercentage) / 100);

    {
      address[] memory assets = new address[](1);
      assets[0] = LP_XSGD;
      address[] memory sources = new address[](1);
      sources[0] = address(new MockAggregator(newPrice));
      vm.prank(oracleOwner);
      AaveOracle(aaveOracle).setAssetSources(assets, sources);
    }

    return newPrice;
  }
}

interface IOracle {
  function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
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

  function viewParameters() external view returns (uint256, uint256, uint256, uint256, uint256);

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
