pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';

import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {AaveOracle} from '../contracts/misc/AaveOracle.sol';
import {ILendingPool} from '../contracts/interfaces/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPoolConfigurator} from '../contracts/interfaces/ILendingPoolConfigurator.sol';
import {LendingPoolConfigurator} from '../contracts/protocol/lendingpool/LendingPoolConfigurator.sol';
import {Errors} from '../contracts/protocol/libraries/helpers/Errors.sol';
import {DataTypes} from '../contracts/protocol/libraries/types/DataTypes.sol';
import {IAToken} from '../contracts/interfaces/IAToken.sol';
import {AToken} from '../contracts/protocol/tokenization/AToken.sol';
import {VariableDebtToken} from '../contracts/protocol/tokenization/VariableDebtToken.sol';
import {StableDebtToken} from '../contracts/protocol/tokenization/StableDebtToken.sol';
import {LendingPool} from '../contracts/protocol/lendingpool/LendingPool.sol';
import {DefaultReserveInterestRateStrategy} from '../contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {IAaveIncentivesController} from '../contracts/interfaces/IAaveIncentivesController.sol';
// import {UpdateATokenInput, UpdateDebtTokenInput } from '../contracts/interfaces/ILendingPoolConfigurator.sol';

import {FXLPEthPriceFeedOracle} from '../contracts/xave-oracles/FXLPEthPriceFeedOracle.sol';

import {OpsConfigHelper, IOpsTestData} from './helpers/OpsConfigHelper.sol';

import {MockAggregator} from './helpers/MockAggregator.sol';

import {IHaloUiPoolDataProvider} from '../contracts/misc/interfaces/IHaloUiPoolDataProvider.sol';

import {ReserveConfiguration} from '../contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

import {UiHaloPoolDataProvider} from '../contracts/misc/UiHaloPoolDataProvider.sol';

import {WalletBalanceProvider} from '../contracts/misc/WalletBalanceProvider.sol';

// forge test -w -vv --match-path test/LendingMarketOpsTestAdmin.t.sol
contract LendingMarketOpsTestAdmin is Test, OpsConfigHelper {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  string private NETWORK = 'AVALANCHE';
  string private RPC_URL = vm.envString(string(abi.encodePacked(NETWORK, '_RPC_URL')));

  uint256 constant LP_TOKEN_PRICE_DISCOUNT_BIPS = 8000;
  uint256 constant BIPS_SCALE = 1e4;

  IOpsTestData.Root root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));

  ILendingPool lendingPoolContract = ILendingPool(root.lendingPool.lendingPoolProxy);

  DataTypes.ReserveData private _reserveData;

  function setUp() public {
    vm.createSelectFork(RPC_URL, root.blockchain.forkBlock);
  }

  function testLendingMarketAddresses() public {
    console.log('Running tests in network: %s', NETWORK);
    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(
      lendingPoolContract.getAddressesProvider()
    );

    assertEq(root.lendingPool.admin, lpAddrProvider.getPoolAdmin(), 'correct pool admin set');

    assertEq(root.lendingPool.lendingPoolProxy, lpAddrProvider.getLendingPool(), 'correct lending pool set');

    assertEq(
      lpAddrProvider.getLendingPoolConfigurator(),
      root.lendingPool.poolConfigurator,
      'correct lending pool configurator set'
    );

    assertEq(
      root.lendingPool.collateralManager,
      lpAddrProvider.getLendingPoolCollateralManager(),
      'correct lending pool collateral manager set'
    );

    assertEq(root.lendingPool.emergencyAdmin, lpAddrProvider.getEmergencyAdmin(), 'correct emergency admin set');

    assertEq(root.lendingPool.priceOracle, lpAddrProvider.getPriceOracle(), 'correct price oracle set');

    assertEq(
      root.lendingPool.lendingRateOracle,
      lpAddrProvider.getLendingRateOracle(),
      'correct lending rate oracle set'
    );
  }

  function testLendingPoolPauseAndUnpause() public {
    vm.expectRevert(bytes(Errors.LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR));
    lendingPoolContract.setPause(true);

    vm.startPrank(root.lendingPool.poolConfigurator);

    lendingPoolContract.setPause(true);
    assertEq(lendingPoolContract.paused(), true, 'reserve paused');
    lendingPoolContract.setPause(false);
    assertEq(lendingPoolContract.paused(), false, 'reserve unpaused');
    vm.stopPrank();
  }

  function testEnableAndDisableReserveBorrowing() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.disableBorrowingOnReserve(root.tokens.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.disableBorrowingOnReserve(root.tokens.usdc);
    vm.stopPrank();

    _reserveData = lendingPoolContract.getReserveData(root.tokens.usdc);

    assertEq(_reserveData.configuration.getBorrowingEnabled(), false, 'USDC borrowing disabled');

    // enableBorrowingOnReserve
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.enableBorrowingOnReserve(root.tokens.usdc, true);

    vm.startPrank(root.lendingPool.admin);
    lpc.enableBorrowingOnReserve(root.tokens.usdc, true);
    vm.stopPrank();

    _reserveData = lendingPoolContract.getReserveData(root.tokens.usdc);
    assertEq(_reserveData.configuration.getBorrowingEnabled(), true, 'USDC borrowing enabled');
  }

  function testActivateAndDeactivateReserve() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    DataTypes.ReserveData memory baseData = lendingPoolContract.getReserveData(root.tokens.usdc);
    (bool isActive, , , ) = baseData.configuration.getFlagsMemory();

    vm.startPrank(root.lendingPool.admin);
    assertEq(isActive, true);

    // deactivate reserve
    lpc.deactivateReserve(root.tokens.usdc);

    DataTypes.ReserveData memory baseDataAfterDeactivate = lendingPoolContract.getReserveData(root.tokens.usdc);
    (bool isActiveAfterDeactivate, , , ) = baseDataAfterDeactivate.configuration.getFlagsMemory();
    assertEq(isActiveAfterDeactivate, false);

    // activate again
    lpc.activateReserve(root.tokens.usdc);
    DataTypes.ReserveData memory baseDataAfterActivate = lendingPoolContract.getReserveData(root.tokens.usdc);
    (bool isActiveAfterActivate, , , ) = baseDataAfterActivate.configuration.getFlagsMemory();
    assertEq(isActiveAfterActivate, true);

    vm.stopPrank();

    // not pool admin tests
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.deactivateReserve(root.tokens.usdc);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.activateReserve(root.tokens.usdc);
  }

  function testFreezeAndUnfreezeReserve() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.freezeReserve(root.tokens.usdc);

    vm.prank(root.lendingPool.admin);
    lpc.freezeReserve(root.tokens.usdc);

    _reserveData = lendingPoolContract.getReserveData(root.tokens.usdc);
    assertEq(_reserveData.configuration.getFrozen(), true, 'USDC reserve frozen');

    // TODO: Add LP user deposit reserve to test if reserve is frozen (add expect revert)
    vm.prank(root.blockchain.eoaWallet);
    vm.expectRevert();
    lendingPoolContract.deposit(root.tokens.usdc, 1000 * 1e6, root.blockchain.eoaWallet, 0);

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.unfreezeReserve(root.tokens.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.unfreezeReserve(root.tokens.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    _reserveData = lendingPoolContract.getReserveData(root.tokens.usdc);

    assertEq(_reserveData.configuration.getFrozen(), false, 'USDC reserve unfroze');
  }

  function testEnableAndDisableReserveStableRate() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.disableReserveStableRate(root.tokens.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.disableReserveStableRate(root.tokens.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    _reserveData = lendingPoolContract.getReserveData(root.tokens.usdc);

    assertEq(_reserveData.configuration.getStableRateBorrowingEnabled(), false, 'USDC stable rate disabled');

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.enableReserveStableRate(root.tokens.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.enableReserveStableRate(root.tokens.usdc);
    vm.stopPrank();

    _reserveData = lendingPoolContract.getReserveData(root.tokens.usdc);
    assertEq(_reserveData.configuration.getStableRateBorrowingEnabled(), true, 'USDC stable rate enabled');
  }

  function testSetReserveFactor() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.setReserveFactor(root.tokens.usdc, 0);

    vm.startPrank(root.lendingPool.admin);
    lpc.setReserveFactor(root.tokens.usdc, 0);
    vm.stopPrank();

    _reserveData = lendingPoolContract.getReserveData(root.tokens.usdc);

    assertEq(_reserveData.configuration.getReserveFactor(), 0, 'USDC reserve factor set to 0');
  }

  function testSetReserveInterestRateStrategyAddress() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.setReserveInterestRateStrategyAddress(root.tokens.usdc, 0x0000000000000000000000000000000000000000);

    vm.startPrank(root.lendingPool.admin);
    lpc.setReserveInterestRateStrategyAddress(root.tokens.usdc, 0x0000000000000000000000000000000000000000);
    vm.stopPrank();

    DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.tokens.usdc);

    assertEq(usdcReserveData.interestRateStrategyAddress, 0x0000000000000000000000000000000000000000);
  }

  function testUpdateATokens() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    // TODO: Actual deployment of proxy implementation contract
    address aTokenImpl = address(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);

    ILendingPoolConfigurator.UpdateATokenInput memory input = ILendingPoolConfigurator.UpdateATokenInput({
      asset: root.tokens.xsgd,
      treasury: root.fxPool.vault,
      incentivesController: aTokenImpl,
      name: 'aXSGD',
      symbol: 'aXSGD',
      implementation: aTokenImpl,
      params: bytes('0x')
    });

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.updateAToken(input);

    // vm.startPrank(root.lendingPool.admin);
    // lpc.updateAToken(input);
    // vm.stopPrank();

    // DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.tokens.usdc);

    // assertEq(usdcReserveData.interestRateStrategyAddress, 0x0000000000000000000000000000000000000000);
  }

  function testUpdateStableDebtToken() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    // TODO: Actual deployment of incentives controller
    address aTokenImpl = address(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);
    StableDebtToken sdt = new StableDebtToken();

    sdt.initialize(
      ILendingPool(root.lendingPool.lendingPoolProxy),
      root.tokens.usdc,
      IAaveIncentivesController(0x0000000000000000000000000000000000000000),
      18,
      'Test USDC Debt Token',
      'TDUSDC',
      bytes('0x')
    );

    ILendingPoolConfigurator.UpdateDebtTokenInput memory input = ILendingPoolConfigurator.UpdateDebtTokenInput({
      asset: root.tokens.xsgd,
      incentivesController: aTokenImpl,
      name: 'aXSGD',
      symbol: 'aXSGD',
      implementation: address(sdt),
      params: bytes('0x')
    });

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.updateStableDebtToken(input);

    // vm.startPrank(root.lendingPool.admin);
    // lpc.updateStableDebtToken(input);
    // vm.stopPrank();

    // DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.tokens.usdc);

    // assertEq(usdcReserveData.stableDebtTokenAddress, address(sdt));
  }

  function testUpdateVariableDebtToken() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    // TODO: Actual deployment of proxy implementation contract
    address aTokenImpl = address(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);

    ILendingPoolConfigurator.UpdateDebtTokenInput memory input = ILendingPoolConfigurator.UpdateDebtTokenInput({
      asset: root.tokens.xsgd,
      incentivesController: aTokenImpl,
      name: 'aXSGD',
      symbol: 'aXSGD',
      implementation: aTokenImpl,
      params: bytes('0x')
    });

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.updateVariableDebtToken(input);

    // vm.startPrank(root.lendingPool.admin);
    // lpc.updateVariableDebtToken(input);
    // vm.stopPrank();

    // DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.tokens.usdc);

    // assertEq(usdcReserveData.variableDebtTokenAddress, 0x0000000000000000000000000000000000000000);
  }

  // TODO: Break down into different tests. Create internal functions for each operation so that it can be reused for state flow dependency
  function testLPUserOperations() public {
    _getTokenBalances(root.blockchain.eoaWallet);

    (, int256 ethUsdPrice, , , ) = IOracle(root.chainlink.ethUsd).latestRoundData();
    (, int256 usdcUsdPrice, , , ) = IOracle(root.chainlink.usdcUsd).latestRoundData();

    (uint256 totalCollateralETHBeforeDeposit, , uint256 availableBorrowsETHBeforeDeposit, , , ) = lendingPoolContract
      .getUserAccountData(root.blockchain.eoaWallet);

    // Note: User wallet deposits FXP (testing FXP token is already added as reserve from foundry deployment script)
    _putCollateralInLendingPool(root.blockchain.eoaWallet, root.fxPool.fxp, 1000 * 1e18);

    (uint256 totalCollateralETHAfterDeposit, , uint256 availableBorrowsETHAfterDeposit, , , ) = lendingPoolContract
      .getUserAccountData(root.blockchain.eoaWallet);
    assertGt(totalCollateralETHAfterDeposit, totalCollateralETHBeforeDeposit, 'Collateral increased after deposit');
    assertGt(
      availableBorrowsETHAfterDeposit,
      availableBorrowsETHBeforeDeposit,
      'Borrowing capacity increased after deposit'
    );

    {
      uint256 maxAvailableUsdcBorrows = (((availableBorrowsETHAfterDeposit * uint256(ethUsdPrice) * 1e6) /
        uint256(usdcUsdPrice)) / 1e18);

      uint256 usdcBalBeforeBorrow = IERC20(root.tokens.usdc).balanceOf(root.blockchain.eoaWallet);

      // Note: Another LP deposit USDC to ensure there is USDC reserve balance
      _putCollateralInLendingPool(root.lendingPool.donor, root.tokens.usdc, 10_000 * 1e6);

      (, , , , , uint256 healthFactorBeforeBorrow) = lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

      _borrowFromLendingPool(root.blockchain.eoaWallet, root.tokens.usdc, maxAvailableUsdcBorrows);

      uint256 usdcBalAfterBorrow = IERC20(root.tokens.usdc).balanceOf(root.blockchain.eoaWallet);

      (, , , , , uint256 healthFactorAfterBorrow) = lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

      assertEq(
        usdcBalAfterBorrow,
        usdcBalBeforeBorrow + (maxAvailableUsdcBorrows),
        'USDC balance increased after borrow'
      );
      assertLt(healthFactorAfterBorrow, healthFactorBeforeBorrow, 'Health factor decreased after borrow');

      address aaveOracle = ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPriceOracle();

      {
        uint256 lpTokenPrice = AaveOracle(aaveOracle).getAssetPrice(root.fxPool.fxp);

        (, , , , , uint256 healthFactorBeforePriceManipulation) = lendingPoolContract.getUserAccountData(
          root.blockchain.eoaWallet
        );

        _manipulatePriceOracle(root.fxPool.fxp, int256((lpTokenPrice * LP_TOKEN_PRICE_DISCOUNT_BIPS) / BIPS_SCALE), 18);

        (, , , , , uint256 healthFactorAfterPriceManipulation) = lendingPoolContract.getUserAccountData(
          root.blockchain.eoaWallet
        );

        assertGt(
          healthFactorBeforePriceManipulation,
          healthFactorAfterPriceManipulation,
          'Health factor decreased after price manipulation'
        );
      }

      uint256 amtToLiquidate = (maxAvailableUsdcBorrows * LP_TOKEN_PRICE_DISCOUNT_BIPS) / BIPS_SCALE;
      
      uint256 liquidatorUsdcBalanceBeforeLiquidating = IERC20(root.tokens.usdc).balanceOf(root.lendingPool.donor);
      (uint256 totalCollateralBeforeLiqudation, , , , , ) = lendingPoolContract.getUserAccountData(
        root.blockchain.eoaWallet
      );

      _liquidatePosition(
        root.lendingPool.donor,
        root.blockchain.eoaWallet,
        root.fxPool.fxp,
        root.tokens.usdc,
        amtToLiquidate,
        true
      );

      {
        uint256 liquidatorUsdcBalanceAfterLiquidating = IERC20(root.tokens.usdc).balanceOf(root.lendingPool.donor);
        (uint256 totalCollateralAfterLiqudation, , , , , ) = lendingPoolContract.getUserAccountData(
          root.blockchain.eoaWallet
        );

        assertLt(
          liquidatorUsdcBalanceAfterLiquidating,
          liquidatorUsdcBalanceBeforeLiquidating,
          'Liquidator USDC balance decreased after liquidation, used in paying off liquidation'
        );

        assertLt(
          totalCollateralAfterLiqudation,
          totalCollateralBeforeLiqudation,
          'Total collateral decreased after liquidation'
        );
      }

      vm.startPrank(root.blockchain.eoaWallet);
      IERC20(root.tokens.usdc).approve(root.lendingPool.lendingPoolProxy, type(uint256).max);

      uint256 xsgdLpBalBeforeRepay = IERC20(root.fxPool.fxp).balanceOf(root.blockchain.eoaWallet);
      (, , , , , uint256 healthFactorBeforeRepay) = lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

      lendingPoolContract.repay(
        root.tokens.usdc,
        maxAvailableUsdcBorrows,
        2, // stablecoin borrowing
        root.blockchain.eoaWallet
      );

      vm.stopPrank();

      {
        (, , , , , uint256 healthFactorAfterRepay) = lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);
        assertGt(healthFactorAfterRepay, healthFactorBeforeRepay, 'Health factor increased after repay');
      }

      assertGt(
        usdcBalAfterBorrow,
        IERC20(root.tokens.usdc).balanceOf(root.blockchain.eoaWallet),
        'USDC balance decreased after repay'
      );

      uint256 fxpBalanceBeforeWithdraw = IERC20(root.fxPool.fxp).balanceOf(root.blockchain.eoaWallet);

      vm.prank(root.blockchain.eoaWallet);
      lendingPoolContract.withdraw(root.fxPool.fxp, 1 * 1e18, root.blockchain.eoaWallet);

      {
        uint256 fxpBalanceAfterWithdraw = IERC20(root.fxPool.fxp).balanceOf(root.blockchain.eoaWallet);
        assertEq(
          fxpBalanceAfterWithdraw,
          fxpBalanceBeforeWithdraw + 1 * 1e18,
          'LP Token balance increased after withdraw'
        );
      }

      assertGt(
        IERC20(root.fxPool.fxp).balanceOf(root.blockchain.eoaWallet),
        xsgdLpBalBeforeRepay,
        'LP Token balance increased after withdraw'
      );
    }
  }

  function _getTokenBalances(address receiver) private {
    vm.startPrank(root.faucets.usdcWhale);
    IERC20(root.tokens.usdc).transfer(receiver, 10_000 * 1e6);
    vm.stopPrank();

    vm.startPrank(root.faucets.xsgdWhale);
    IERC20(root.tokens.xsgd).transfer(receiver, 10_000 * 1e6);
    vm.stopPrank();

    _addLiquidity(IFXPool(root.fxPool.fxp).getPoolId(), 2_000 * 1e18, receiver, root.tokens.usdc, root.tokens.xsgd);
  }

  function _getReservesData() private {
    (IHaloUiPoolDataProvider.AggregatedReserveData[] memory reservesData, ) = IHaloUiPoolDataProvider(
      root.lendingPool.uiDataProvider
    ).getReservesData(ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider));
    console2.log('reservesData.length', reservesData.length);
    for (uint256 i = 0; i < reservesData.length; i++) {
      if (reservesData[i].underlyingAsset == root.fxPool.fxp)
        console2.log('reserve reserveLiquidationThreshold', reservesData[i].reserveLiquidationThreshold);
    }
  }

  function _putCollateralInLendingPool(address depositor, address token, uint256 amount) private {
    vm.startPrank(depositor);
    IERC20(token).approve(root.lendingPool.lendingPoolProxy, type(uint256).max);
    lendingPoolContract.deposit(
      token,
      amount,
      depositor,
      0 // referral code
    );
    vm.stopPrank();
  }

  function _borrowFromLendingPool(address borrower, address token, uint256 amount) private {
    vm.startPrank(borrower);
    lendingPoolContract.borrow(
      token,
      amount,
      2, // stablecoin borrowing
      0, // referral code
      borrower
    );
    vm.stopPrank();
  }

  function _manipulatePriceOracle(address asset, int256 price, uint8 decimals) private returns (MockAggregator) {
    address aaveOracle = ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPriceOracle();
    MockAggregator manipulatedLPOracle = new MockAggregator(price, decimals);

    address[] memory assets = new address[](1);
    assets[0] = asset;
    address[] memory sources = new address[](1);
    sources[0] = address(manipulatedLPOracle);

    vm.prank(root.lendingPool.oracleOwner);
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    return manipulatedLPOracle;
  }

  function _liquidatePosition(
    address liquidator,
    address liquidatee,
    address collateralToken,
    address paymentToken,
    uint256 amount,
    bool inATokens
  ) private {
    vm.startPrank(liquidator);
    IERC20(root.tokens.usdc).approve(root.lendingPool.lendingPoolProxy, amount);
    lendingPoolContract.liquidationCall(collateralToken, paymentToken, liquidatee, amount, inATokens);
    vm.stopPrank();
  }

  function _repayLoan(address repayer, address token, uint256 amount) private {
    vm.startPrank(repayer);
    IERC20(token).approve(root.lendingPool.lendingPoolProxy, amount);
    lendingPoolContract.repay(
      token,
      amount,
      2, // stablecoin borrowing
      repayer
    );
    vm.stopPrank();
  }

  function _deployOracle(address asset, address baseAssim, address quoteAssim) internal returns (address) {
    FXLPEthPriceFeedOracle lpOracle = new FXLPEthPriceFeedOracle(
      asset,
      root.chainlink.ethUsd, // ETH USD Oracle
      'LPXSGD-USDC/ETH'
    );

    return address(lpOracle);
  }

  function _addNewReserve() private {
    // Deploy reserve
    _deployReserve();

    // TODO: Query this from FX Pool value so value is dynamic when we use this test in different network

    (IERC20[] memory tokens, , ) = IVault(root.fxPool.vault).getPoolTokens(IFXPool(root.fxPool.fxp).getPoolId());

    address baseAssimilator = IFXPool(root.fxPool.fxp).assimilator(address(tokens[0]));
    address quoteAssimilator = IFXPool(root.fxPool.fxp).assimilator(address(tokens[1]));

    // Set Oracle for asset
    address lpOracle = _deployOracle(root.fxPool.fxp, baseAssimilator, quoteAssimilator);

    // Set oracle source for asset
    address aaveOracle = ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPriceOracle();

    address[] memory assets = new address[](1);
    assets[0] = root.fxPool.fxp;
    address[] memory sources = new address[](1);
    sources[0] = address(lpOracle);

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    vm.prank(root.lendingPool.oracleOwner);
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    uint256 _price = AaveOracle(aaveOracle).getAssetPrice(root.fxPool.fxp);

    // testConfigureReserveAsCollateral

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    LendingPoolConfigurator(root.lendingPool.poolConfigurator).configureReserveAsCollateral(
      root.fxPool.fxp,
      root.reserveConfigs.fxpLp.baseLtv,
      root.reserveConfigs.fxpLp.liquidationBonus,
      root.reserveConfigs.fxpLp.liquidationThreshold
    );

    address poolAdmin = ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPoolAdmin();

    vm.startPrank(poolAdmin);

    LendingPoolConfigurator(root.lendingPool.poolConfigurator).configureReserveAsCollateral(
      root.fxPool.fxp,
      root.reserveConfigs.fxpLp.baseLtv,
      root.reserveConfigs.fxpLp.liquidationBonus,
      root.reserveConfigs.fxpLp.liquidationThreshold
    );
    vm.stopPrank();
  }

  function _deployReserve() private {
    address XAVE_TREASURY = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;

    // Deploy Aave Tokens
    AToken aToken = new AToken();
    aToken.initialize(
      lendingPoolContract,
      XAVE_TREASURY,
      root.fxPool.fxp,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(root.fxPool.fxp).decimals(),
      'aXSGD-USDC',
      'aXSGD-USDC',
      bytes('')
    );

    StableDebtToken sdt = new StableDebtToken();
    sdt.initialize(
      lendingPoolContract,
      root.fxPool.fxp,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(root.fxPool.fxp).decimals(),
      'sbtXSGD-USDC',
      'sbtXSGD-USDC',
      bytes('')
    );
    VariableDebtToken vdt = new VariableDebtToken();

    vdt.initialize(
      lendingPoolContract,
      root.fxPool.fxp,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(root.fxPool.fxp).decimals(),
      'vdtXSGD-USDC',
      'vdtXSGD-USDC',
      bytes('')
    );

    // Deploy default reserve interest strategy
    DefaultReserveInterestRateStrategy dris = new DefaultReserveInterestRateStrategy(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider),
      0.9 * 1e27, // optimal utilization rate
      0 * 1e27, // baseVariableBorrowRate
      0.04 * 1e27, // variableRateSlope1
      0.60 * 1e27, // variableRateSlope2
      0.02 * 1e27, // stableRateSlope1
      0.60 * 1e27 // stableRateSlope2
    );

    // Deploy Reserve
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    ILendingPoolConfigurator.InitReserveInput[] memory input = new ILendingPoolConfigurator.InitReserveInput[](1);
    input[0] = ILendingPoolConfigurator.InitReserveInput({
      aTokenImpl: address(aToken),
      stableDebtTokenImpl: address(sdt),
      variableDebtTokenImpl: address(vdt),
      underlyingAssetDecimals: IERC20Detailed(root.fxPool.fxp).decimals(),
      interestRateStrategyAddress: address(dris),
      underlyingAsset: root.fxPool.fxp,
      treasury: XAVE_TREASURY,
      incentivesController: address(0),
      underlyingAssetName: 'XSGD-USDC',
      aTokenName: 'aXSGD-USDC',
      aTokenSymbol: 'aXSGD-USDC',
      variableDebtTokenName: vdt.name(),
      variableDebtTokenSymbol: vdt.symbol(),
      stableDebtTokenName: sdt.name(),
      stableDebtTokenSymbol: sdt.symbol(),
      params: bytes('')
    });

    vm.prank(ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPoolAdmin());
    lpc.batchInitReserve(input);
  }

  /**
   In future, Test incentive emission?
    */

  function _addLiquidity(bytes32 _poolId, uint256 _depositNumeraire, address _user, address _tA, address _tB) private {
    (_tA, _tB) = _tA < _tB ? (_tA, _tB) : (_tB, _tA);

    address[] memory assets = new address[](2);
    assets[0] = _tA;
    assets[1] = _tB;

    uint256[] memory maxAmountsIn = new uint256[](2);
    maxAmountsIn[0] = type(uint256).max;
    maxAmountsIn[1] = type(uint256).max;

    uint256[] memory minAmountsOut = new uint256[](2);
    minAmountsOut[0] = 0;
    minAmountsOut[1] = 0;

    address[] memory userAssets = new address[](2);
    userAssets[0] = _tA;
    userAssets[1] = _tB;
    bytes memory userDataJoin = abi.encode(_depositNumeraire, userAssets);

    IVault.JoinPoolRequest memory reqJoin = IVault.JoinPoolRequest(
      _asIAsset(assets),
      maxAmountsIn,
      userDataJoin,
      false
    );

    vm.startPrank(_user);
    IERC20(_tA).approve(root.fxPool.vault, type(uint256).max);
    IERC20(_tB).approve(root.fxPool.vault, type(uint256).max);
    IVault(root.fxPool.vault).joinPool(_poolId, _user, _user, reqJoin);
    vm.stopPrank();
  }

  function _asIAsset(address[] memory addresses) private pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      assets := addresses
    }
  }
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}

interface IVault {
  function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;

  struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function getPoolTokens(
    bytes32 poolId
  ) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
}

interface IAsset {
  // solhint-disable-previous-line no-empty-blocks
}

interface IFXPool {
  function liquidity() external view returns (uint256, uint256[] memory);

  function totalSupply() external view returns (uint256);

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);

  function protocolPercentFee() external view returns (uint256);

  function viewDeposit(uint256) external view returns (uint256);

  function getPoolId() external view returns (bytes32);

  function assimilator(address _derivative) external view returns (address);
}

interface IOracle {
  function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

interface ILendingPoolAddressesProviderWithOwner is ILendingPoolAddressesProvider {
  function owner() external view returns (address);
}
