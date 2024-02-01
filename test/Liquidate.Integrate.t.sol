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

interface IOracle {
  function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

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
  // Vm.Wallet memory RICH_GUY = vm.createWallet(walletLabel);

  address constant RICH_GUY = 0x1B736B89cd70Cf355d71f55E626Dc53E8D56Bc2E;

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);

    vm.prank(XSGD_HOLDER);
    IERC20(XSGD).transfer(me, 5_000_000 * 1e6);
    IERC20(XSGD).transfer(RICH_GUY, 1_000_000 * 1e6);

    vm.prank(USDC_HOLDER);
    IERC20(USDC).transfer(me, 5_000_000 * 1e6);
    IERC20(USDC).transfer(RICH_GUY, 1_000_000 * 1e6);
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
  function testLiquidate() public {
    _printUserAccountData(me);

    (, int256 ethUsdPrice, , , ) = IOracle(ETH_USD_CHAINLINK).latestRoundData();
    (, int256 usdcUsdPrice, , , ) = IOracle(USDC_USD_CHAINLINK).latestRoundData();
    console.log('ethUsdPrice', uint256(ethUsdPrice));
    console.log('usdcUsdPrice', uint256(usdcUsdPrice));

    _deployReserve();
    lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    // Set Lending market oracle for XSGD_USDC token to use newly deployed HLPOracle
    _setXsgdHLPOracle(lpOracle);

    int256 lpPrice = IHLPOracle(lpOracle).latestAnswer();
    // console.log('lpPrice', uint256(lpPrice));
    // console2.log('baseContract', IHLPOracle(lpOracle).baseContract());
    console2.log('ETC/USD price', uint256(IHLPOracle(IHLPOracle(lpOracle).quotePriceFeed()).latestAnswer()));

    vm.startPrank(me);

    // Add liq to FX Pool to get LP_XSGD balance
    IERC20(XSGD).approve(BALANCER_VAULT, type(uint).max);
    IERC20(USDC).approve(BALANCER_VAULT, type(uint).max);

    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);

    console.log('LP_XSGD balance after add liq', IERC20(LP_XSGD).balanceOf(me) / 1e18);

    // Deposit collateral to use for borrowing later
    IERC20(LP_XSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);
    LP.deposit(
      LP_XSGD,
      10_000 * 1e18,
      me,
      0 // referral code
    );

    // User sets LP_XSGD to be used as collateral in lending market pool
    LP.setUserUseReserveAsCollateral(LP_XSGD, true);

    vm.stopPrank();

    // IERC20(aLPXSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max); // not needed

    // idea: (other people deposit in lending pool to put collateral borrowable balance to solve VL_COLLATERAL_BALANCE_IS_0)
    _putBorrowableLiquidityInLendingPool(RICH_GUY, 1_000_000 * 1e6);

    DataTypes.ReserveData memory rdLPXSGD = LP.getReserveData(LP_XSGD);
    address aLPXSGD = rdLPXSGD.aTokenAddress;

    console.log('aLPXSGD', IERC20(aLPXSGD).balanceOf(me));

    /**
      1. Check borrowing enabled
      2. Check all reserves tapos check kung tama yung aTokenAddresss ()
      3. IAaveOracle(aaveOracle).getAssetPrice() if has price (yes)
     */

    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
    console.log('LP XSGD Aave asset price', IAaveOracle(aaveOracle).getAssetPrice(LP_XSGD));

    _getLendingPoolReserveConfig();

    console.log('---- User Lending Market Balance After Deposit Before Borrow ----');
    _printUserAccountData(me);

    // Enable borrowing for added LP assets
    _enableBorrowingForAddedLPAssets(LP_XSGD, true);
    console.log('--- Enabled borrowing for LP XSGD ---');

    _getLendingPoolReserveConfig();

    // Borrow up to the limit of your collateral
    _borrowToLimit(me);

    // _repayLoan(me); // repay the loan

    // _depositWithdraw(); // deposit and withdraw

    // get the price for the collateral

    IHaloUiPoolDataProvider.UserReserveData[] memory userReserves = IHaloUiPoolDataProvider(UI_DATA_PROVIDER)
      .getUserReservesData(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER), me);

    console.log(userReserves[0].underlyingAsset, userReserves[0].scaledATokenBalance);
    console.log(userReserves[1].underlyingAsset, userReserves[1].scaledATokenBalance);
    console.log(userReserves[2].underlyingAsset, userReserves[2].scaledATokenBalance);
    console.log(userReserves[3].underlyingAsset, userReserves[3].scaledATokenBalance);
    console.log(userReserves[4].underlyingAsset, userReserves[4].scaledATokenBalance);
    console.log(userReserves[5].underlyingAsset, userReserves[5].scaledATokenBalance);
    console.log(userReserves[6].underlyingAsset, userReserves[6].scaledATokenBalance);

    _manipulateOraclePrice();

    _liquididatePosition(me);

    // manipulate the oracle to make the loan undercollateralized

    // liquidate the loan

    // check that the liquidator received the collateral
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
    vm.stopPrank();

    console2.log('[_setXsgdHLPOracle] Done setting price oracle for XSGD_USDC collateral', lpOracle);
  }

  function _borrowToLimit(address _user) private {
    // Is this still needed if we are deploying a new lpOracle?
    // I think yes to point the newly deployed lpOracle to the correct HLP
    // _setXsgdHLPOracle(lpOracle);

    (
      ,
      /*uint256 totalCollateralETH*/
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    ) = LP.getUserAccountData(_user);
    console.log('[_borrowToLimit] healthFactor', healthFactor);

    (, int256 ethUsdPrice, , , ) = IOracle(ETH_USD_CHAINLINK).latestRoundData();
    (, int256 usdcUsdPrice, , , ) = IOracle(USDC_USD_CHAINLINK).latestRoundData();

    vm.startPrank(_user);
    // @note might be rounding off issue?
    uint256 totalUsdcBorrows = (((availableBorrowsETH - totalDebtETH) * (uint256(ethUsdPrice))) /
      uint256(usdcUsdPrice)) / 1e12;

    console.log('[_borrowToLimit] totalUsdcBorrows', totalUsdcBorrows);

    uint256 balBefore = IERC20(USDC).balanceOf(_user);
    console.log('[_borrowToLimit] balBefore', balBefore);

    LP.borrow(
      USDC,
      totalUsdcBorrows + uint256(1169 * 1e6), // @todo check if it make sense: difference between total calculated usdc to be borrowed vs actual limit
      2, // stablecoin borrowing
      0, // referral code
      _user
    );

    uint256 balAfter = IERC20(USDC).balanceOf(_user);
    console.log('[_borrowToLimit] balAfter', balAfter);

    (
      ,
      ,
      /*uint256 totalCollateralETH*/ uint256 availableBorrowsETH2,
      uint256 currentLiquidationThreshold2 /*uint256 ltv*/,
      ,
      uint256 healthFactor2
    ) = LP.getUserAccountData(_user);

    console.log('[_borrowToLimit] availableBorrowsETH2', availableBorrowsETH2);
    console.log('[_borrowToLimit] healthFactor2: ', healthFactor2);

    vm.stopPrank();
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
    // vm.startPrank(ILendingPoolAddressesProvider.getPoolAdmin());
    // ILendingPoolConfigurator(lendingPoolConfigurator).enableBorrowingOnReserve(_asset, doEnable);
    // vm.stopPrank();
  }

  function _printHealthFactor(address _user) private {
    (
      ,
      ,
      ,
      ,
      ,
      /*uint256 totalCollateralETH*/
      /*uint256 totalDebtETH*/ /*uint256 availableBorrowsETH*/ /*uint256 currentLiquidationThreshold*/ /*uint256 ltv*/ uint256 healthFactor
    ) = LP.getUserAccountData(_user);
    console.log('healthFactor\t', healthFactor);
  }

  function _printUserAccountData(address _user) private {
    (
      ,
      //uint256 totalCollateralETH
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      ,
      /*uint256 ltv*/ uint256 healthFactor
    ) = LP.getUserAccountData(_user);
    // console.log('totalCollateralETH', totalCollateralETH);
    console.log('totalDebtETH', totalDebtETH);

    console.log('availableBorrowsETH', availableBorrowsETH);
    console.log('currentLiquidationThreshold', currentLiquidationThreshold);
    console.log('healthFactor', healthFactor);
    // console.log('currentLiquidationThreshold', currentLiquidationThreshold);
    // console.log('ltv', ltv);
    console.log('healthFactor', healthFactor);
  }

  function _liquididatePosition(address _lpUser) private {
    address me = address(this);

    DataTypes.ReserveData memory rd = LP.getReserveData(USDC);
    address aToken = rd.aTokenAddress;

    // _printLiqIndex();

    console.log('[_liquididatePosition]');
    _printHealthFactor(_lpUser);

    console.log('[_liquididatePosition] aToken', IERC20(aToken).balanceOf(me));

    uint256 beforeBal = IERC20(USDC).balanceOf(me);

    IERC20(USDC).approve(LENDINPOOL_PROXY_ADDRESS, type(uint).max);
    LP.liquidationCall(USDC, USDC, _lpUser, type(uint).max, true);
    _printHealthFactor(_lpUser);

    // check that the liquidator received the collateral
    console.log('[_liquididatePosition] aToken', IERC20(aToken).balanceOf(me));

    LP.withdraw(USDC, type(uint).max, me);
    console.log('[_liquididatePosition] USDC received', IERC20(USDC).balanceOf(me) - beforeBal);
    console.log('[_liquididatePosition] aToken', IERC20(aToken).balanceOf(me));
  }

  function _manipulateOraclePrice() private {
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();

    address oracleOwner = AaveOracle(aaveOracle).owner();
    uint256 _price = AaveOracle(aaveOracle).getAssetPrice(LP_XSGD);

    console.log('price', _price);

    address assSource = AaveOracle(aaveOracle).getSourceOfAsset(LP_XSGD);
    console.log('assSource', assSource);
    console.log('fallbackOracle', AaveOracle(aaveOracle).getFallbackOracle());
    console.log('BASE_CURRENCY', AaveOracle(aaveOracle).BASE_CURRENCY());

    address[] memory assets = new address[](1);
    assets[0] = LP_XSGD;
    address[] memory sources = new address[](1);
    sources[0] = address(new MockAggregator(int256(_price / 2)));
    vm.prank(oracleOwner);
    AaveOracle(aaveOracle).setAssetSources(assets, sources);
  }
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
}
