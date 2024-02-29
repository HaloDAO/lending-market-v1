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
import {
  DefaultReserveInterestRateStrategy
} from '../contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {IAaveIncentivesController} from '../contracts/interfaces/IAaveIncentivesController.sol';
// import {UpdateATokenInput, UpdateDebtTokenInput } from '../contracts/interfaces/ILendingPoolConfigurator.sol';

import {FXLPEthPriceFeedOracle} from '../contracts/xave-oracles/FXLPEthPriceFeedOracle.sol';

import {OpsConfigHelper, IOpsTestData} from './helpers/OpsConfigHelper.sol';

import {MockAggregator} from './helpers/MockAggregator.sol';

import {IHaloUiPoolDataProvider} from '../contracts/misc/interfaces/IHaloUiPoolDataProvider.sol';

import {ReserveConfiguration} from '../contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

// forge test -w -vv --match-path test/LendingMarketOpsTestAdmin.t.sol
contract LendingMarketOpsTestAdmin is Test, OpsConfigHelper {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  //// network dependent config
  //// only the following lines are needed to be changed for different networks
  string private NETWORK = 'sepolia';
  string private RPC_URL = vm.envString('SEPOLIA_RPC_URL');

  // string private NETWORK = 'polygon';
  // string private RPC_URL = vm.envString('POLYGON_RPC_URL');

  //// network dependent config end

  IOpsTestData.Root root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));

  ILendingPool lendingPoolContract = ILendingPool(root.lendingPool.lendingPoolProxy); 

  DataTypes.ReserveData private _reserveData;

  function setUp() public {
    vm.createSelectFork(RPC_URL, root.blockchain.forkBlock);
  }

  function testLendingMarketAddresses() public {
    console.log('Running tests in network: %s', NETWORK);
    ILendingPoolAddressesProvider lpAddrProvider =
      ILendingPoolAddressesProvider(lendingPoolContract.getAddressesProvider());

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

  function _addNewReserve() private {
    // Deploy reserve
    _deployReserve();

    // TODO: Query this from FX Pool value so value is dynamic when we use this test in different network

    (IERC20[] memory tokens, , ) =
      IVault(root.fxPool.vault).getPoolTokens(IFXPool(root.fxPool.xsgdUsdcFxp).getPoolId());

    address baseAssimilator = IFXPool(root.fxPool.xsgdUsdcFxp).assimilator(address(tokens[0]));
    address quoteAssimilator = IFXPool(root.fxPool.xsgdUsdcFxp).assimilator(address(tokens[1]));

    // Set Oracle for asset
    address lpOracle = _deployOracle(root.fxPool.xsgdUsdcFxp, baseAssimilator, quoteAssimilator);

    // Set oracle source for asset
    address aaveOracle = ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPriceOracle();

    address[] memory assets = new address[](1);
    assets[0] = root.fxPool.xsgdUsdcFxp;
    address[] memory sources = new address[](1);
    sources[0] = address(lpOracle);

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    vm.prank(root.lendingPool.oracleOwner);
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    uint256 _price = AaveOracle(aaveOracle).getAssetPrice(root.fxPool.xsgdUsdcFxp);

    // testConfigureReserveAsCollateral

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    LendingPoolConfigurator(root.lendingPool.poolConfigurator).configureReserveAsCollateral(
      root.fxPool.xsgdUsdcFxp,
      root.reserveConfigs.lpXsgdUsdc.baseLtv,
      root.reserveConfigs.lpXsgdUsdc.liquidationBonus,
      root.reserveConfigs.lpXsgdUsdc.liquidationThreshold
    );

    address poolAdmin = ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPoolAdmin();

    vm.startPrank(poolAdmin);

    LendingPoolConfigurator(root.lendingPool.poolConfigurator).configureReserveAsCollateral(
      root.fxPool.xsgdUsdcFxp,
      root.reserveConfigs.lpXsgdUsdc.baseLtv,
      root.reserveConfigs.lpXsgdUsdc.liquidationBonus,
      root.reserveConfigs.lpXsgdUsdc.liquidationThreshold
    );
    vm.stopPrank();
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
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    // enableBorrowingOnReserve
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.enableBorrowingOnReserve(root.reserves.usdc, true);

    vm.startPrank(root.lendingPool.admin);
    lpc.enableBorrowingOnReserve(root.reserves.usdc, true);
    vm.stopPrank();

    uint256 liquidationThreshold = ((lendingPoolContract.getConfiguration(root.reserves.usdc)).data & (16 << 31));
    // console.log('testEnableAndDisableReserveBorrowing liquidationThreshold:', liquidationThreshold);
    console.log(
      '(lendingPoolContract.getConfiguration(root.reserves.usdc)).data',
      (lendingPoolContract.getConfiguration(root.reserves.usdc)).data
    );

    bool usdcBorrowIsEnabled = ((lendingPoolContract.getConfiguration(root.reserves.usdc)).data & (1 << 58)) != 0;
    assertEq(usdcBorrowIsEnabled, true, 'USDC borrowing enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.disableBorrowingOnReserve(root.reserves.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.disableBorrowingOnReserve(root.reserves.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration =
      lendingPoolContract.getConfiguration(root.reserves.usdc);

    assertEq(
      (((lendingPoolContract.getConfiguration(root.reserves.usdc)).data & (1 << 58)) != 0), // bit 58: borrowing is enabled
      false,
      'USDC borrowing disabled'
    );
  }

  function testActivateAndDeactivateReserve() public {
    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
    );

    // enableBorrowingOnReserve
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.activateReserve(root.reserves.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.activateReserve(root.reserves.usdc);
    vm.stopPrank();

    // TODO: Failing in sepolia because the USDC reserve is of different address
    bool usdcReserveActive = ((lendingPoolContract.getConfiguration(root.reserves.usdc)).data & (1 << 56)) != 0;
    assertEq(usdcReserveActive, true, 'USDC borrowing enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.deactivateReserve(root.reserves.usdc);

    vm.startPrank(root.lendingPool.admin);
    // Will fail because [FAIL. Reason: revert: Cannot call fallback function from the proxy admin]
    // vm.expectRevert(); // TODO: Remove once there is a fallback reserve
    lpc.deactivateReserve(root.reserves.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    // DataTypes.ReserveConfigurationMap memory usdcConfiguration =
    //   lendingPool.getConfiguration(root.reserves.usdc);

    // assertEq(
    //   (((lendingPool.getConfiguration(root.reserves.usdc)).data & (1 << 56)) != 0), // bit 56: Reserve is active
    //   false,
    //   'USDC reserve deactivated'
    // );
  }
  function testFreezeAndUnfreezeReserve() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.freezeReserve(root.reserves.usdc);

    vm.prank(root.lendingPool.admin);
    lpc.freezeReserve(root.reserves.usdc);

    // bit 57: reserve is frozen
    bool isFrozen = ((lendingPoolContract.getConfiguration(root.reserves.usdc)).data & (1 << 57)) != 0;
    assertEq(isFrozen, true, 'USDC reserve frozen');

    // TODO: Add LP user deposit reserve to test if reserve is frozen (add expect revert)
    vm.prank(root.blockchain.eoaWallet);
    vm.expectRevert();
    lendingPoolContract.deposit(root.reserves.usdc, 1000 * 1e6, root.blockchain.eoaWallet, 0);

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.unfreezeReserve(root.reserves.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.unfreezeReserve(root.reserves.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration =
      lendingPoolContract.getConfiguration(root.reserves.usdc);

    assertEq(
      (((lendingPoolContract.getConfiguration(root.reserves.usdc)).data & (1 << 57)) != 0), // bit 57: reserve is frozen
      false,
      'USDC reserve unfroze'
    );
  }

  function testEnableAndDisableReserveStableRate() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    ILendingPoolAddressesProvider lpAddrProvider =
      ILendingPoolAddressesProvider(lendingPoolContract.getAddressesProvider());

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.enableReserveStableRate(root.reserves.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.enableReserveStableRate(root.reserves.usdc);
    vm.stopPrank();

    // bit 59: stable rate borrowing enabled
    bool isFrozen = ((lendingPoolContract.getConfiguration(root.reserves.usdc)).data & (1 << 59)) != 0;
    assertEq(isFrozen, true, 'USDC stable rate enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.disableReserveStableRate(root.reserves.usdc);

    vm.startPrank(root.lendingPool.admin);
    lpc.disableReserveStableRate(root.reserves.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration =
      lendingPoolContract.getConfiguration(root.reserves.usdc);

    assertEq(
      (((lendingPoolContract.getConfiguration(root.reserves.usdc)).data & (1 << 59)) != 0), // bit 59: stable rate borrowing enabled
      false,
      'USDC stable rate disabled'
    );
  }

  function testSetReserveFactor() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    ILendingPoolAddressesProvider lpAddrProvider =
      ILendingPoolAddressesProvider(lendingPoolContract.getAddressesProvider());

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.setReserveFactor(root.reserves.usdc, 0);

    vm.startPrank(root.lendingPool.admin);
    lpc.setReserveFactor(root.reserves.usdc, 0);
    vm.stopPrank();

    // bit 64-79: reserve factor

    // Step 1: Shift the data to the right by 64 bits to position the reserve factor in bits 0-15
    uint256 shifted = (lendingPoolContract.getConfiguration(root.reserves.usdc)).data >> 64;

    // Step 2: Apply the mask to isolate bits 0-15, which now contain the reserve factor
    uint256 reserveFactor = shifted & ((1 << 16) - 1);

    assertEq(reserveFactor, 0, 'USDC reserve factor set to 0');
  }

  function testSetReserveInterestRateStrategyAddress() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    ILendingPoolAddressesProvider lpAddrProvider =
      ILendingPoolAddressesProvider(lendingPoolContract.getAddressesProvider());

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.setReserveInterestRateStrategyAddress(root.reserves.usdc, 0x0000000000000000000000000000000000000000);

    vm.startPrank(root.lendingPool.admin);
    lpc.setReserveInterestRateStrategyAddress(root.reserves.usdc, 0x0000000000000000000000000000000000000000);
    vm.stopPrank();

    DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.reserves.usdc);

    assertEq(usdcReserveData.interestRateStrategyAddress, 0x0000000000000000000000000000000000000000);
  }

  function testUpdateATokens() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    ILendingPoolAddressesProvider lpAddrProvider =
      ILendingPoolAddressesProvider(lendingPoolContract.getAddressesProvider());

    // TODO: Actual deployment of proxy implementation contract
    address aTokenImpl = address(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);

    ILendingPoolConfigurator.UpdateATokenInput memory input =
      ILendingPoolConfigurator.UpdateATokenInput({
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

    // DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.reserves.usdc);

    // assertEq(usdcReserveData.interestRateStrategyAddress, 0x0000000000000000000000000000000000000000);
  }

  function testUpdateStableDebtToken() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    // TODO: Actual deployment of proxy implementation contract
    address aTokenImpl = address(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);

    ILendingPoolConfigurator.UpdateDebtTokenInput memory input =
      ILendingPoolConfigurator.UpdateDebtTokenInput({
        asset: root.tokens.xsgd,
        incentivesController: aTokenImpl,
        name: 'aXSGD',
        symbol: 'aXSGD',
        implementation: aTokenImpl,
        params: bytes('0x')
      });

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.updateStableDebtToken(input);

    // vm.startPrank(root.lendingPool.admin);
    // lpc.updateAToken(input);
    // vm.stopPrank();

    // DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.reserves.usdc);

    // assertEq(usdcReserveData.interestRateStrategyAddress, 0x0000000000000000000000000000000000000000);
  }

  function testUpdateVariableDebtToken() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    ILendingPoolAddressesProvider lpAddrProvider =
      ILendingPoolAddressesProvider(lendingPoolContract.getAddressesProvider());

    // TODO: Actual deployment of proxy implementation contract
    address aTokenImpl = address(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);

    ILendingPoolConfigurator.UpdateDebtTokenInput memory input =
      ILendingPoolConfigurator.UpdateDebtTokenInput({
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
    // lpc.updateAToken(input);
    // vm.stopPrank();

    // DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.reserves.usdc);

    // assertEq(usdcReserveData.interestRateStrategyAddress, 0x0000000000000000000000000000000000000000);
  }

  function _deployReserve() private {
    address XAVE_TREASURY = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;

    // Deploy Aave Tokens
    AToken aToken = new AToken();
    aToken.initialize(
      lendingPoolContract,
      XAVE_TREASURY,
      root.fxPool.xsgdUsdcFxp,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(root.fxPool.xsgdUsdcFxp).decimals(),
      'aXSGD-USDC',
      'aXSGD-USDC',
      bytes('')
    );

    StableDebtToken sdt = new StableDebtToken();
    sdt.initialize(
      lendingPoolContract,
      root.fxPool.xsgdUsdcFxp,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(root.fxPool.xsgdUsdcFxp).decimals(),
      'sbtXSGD-USDC',
      'sbtXSGD-USDC',
      bytes('')
    );
    VariableDebtToken vdt = new VariableDebtToken();

    vdt.initialize(
      lendingPoolContract,
      root.fxPool.xsgdUsdcFxp,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(root.fxPool.xsgdUsdcFxp).decimals(),
      'vdtXSGD-USDC',
      'vdtXSGD-USDC',
      bytes('')
    );

    // Deploy default reserve interest strategy
    DefaultReserveInterestRateStrategy dris =
      new DefaultReserveInterestRateStrategy(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider),
        0.9 * 1e27, // optimal utilization rate
        0 * 1e27, // baseVariableBorrowRate
        0.04 * 1e27, // variableRateSlope1
        0.60 * 1e27, // variableRateSlope2
        0.02 * 1e27, // stableRateSlope1
        0.60 * 1e27 // stableRateSlope2
      );

    // Deploy Reserve
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(
        ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getLendingPoolConfigurator()
      );

    ILendingPoolConfigurator.InitReserveInput[] memory input = new ILendingPoolConfigurator.InitReserveInput[](1);
    input[0] = ILendingPoolConfigurator.InitReserveInput({
      aTokenImpl: address(aToken),
      stableDebtTokenImpl: address(sdt),
      variableDebtTokenImpl: address(vdt),
      underlyingAssetDecimals: IERC20Detailed(root.fxPool.xsgdUsdcFxp).decimals(),
      interestRateStrategyAddress: address(dris),
      underlyingAsset: root.fxPool.xsgdUsdcFxp,
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

  function _deployOracle(
    address asset,
    address baseAssim,
    address quoteAssim
  ) internal returns (address) {
    FXLPEthPriceFeedOracle lpOracle =
      new FXLPEthPriceFeedOracle(
        asset,
        root.chainlink.ethUsd, // ETH USD Oracle
        'LPXSGD-USDC/ETH'
      );

    return address(lpOracle);
  }


  // TODO: Break down into different tests. Create internal functions for each operation so that it can be reused for state flow dependency
  function testLPUserOperations() public {
    _getTokenBalances(root.blockchain.eoaWallet);

    (, int256 ethUsdPrice, , , ) = IOracle(root.chainlink.ethUsd).latestRoundData();
    (, int256 usdcUsdPrice, , , ) = IOracle(root.chainlink.usdcUsd).latestRoundData();

    // _addNewReserve();

    (uint256 totalCollateralETHBefore, , , , , uint256 healthFactorBeforeDeposit) =
      lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

    /** *Medium priority*
    - check lending pool balance
   */

  console.log('healthFactorBeforeDeposit', healthFactorBeforeDeposit / 1e27);


    _putCollateralInLendingPool(root.blockchain.eoaWallet, root.fxPool.xsgdUsdcFxp, 1000 * 1e18);

    {
      (, , , , , uint256 healthFactorAfterDeposit) = lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

      console.log('healthFactorAfterDeposit', healthFactorAfterDeposit / 1e27);
    }

    DataTypes.ReserveData memory usdcReserveData = lendingPoolContract.getReserveData(root.reserves.usdc);

    {
      (uint256 totalCollateralETHAfterDeposit, , uint256 availableBorrowsETHAfter, , , uint256 healthFactorAfter) =
        lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

      uint256 maxAvailableUsdcBorrows =
        (((availableBorrowsETHAfter * uint256(ethUsdPrice) * 1e6) / uint256(usdcUsdPrice)) / 1e18);

      uint256 usdcBalBeforeBorrow = IERC20(root.tokens.usdc).balanceOf(root.blockchain.eoaWallet);
      console2.log('totalCollateralETHAfterDeposit', totalCollateralETHAfterDeposit);
      console2.log('availableBorrowsETHAfter', availableBorrowsETHAfter);
      console2.log('usdc bal before borrow', usdcBalBeforeBorrow);
      console2.log('maxAvailableUsdcBorrows', maxAvailableUsdcBorrows);

      // TODO: Another LP deposit USDC to ensure there is USDC reserve balance

      _putCollateralInLendingPool(root.lendingPool.donor, root.tokens.usdc, 10_000 * 1e6);
      

      // BORROW_ALLOWANCE_NOT_ENOUGH 59

      {
        (uint256 totalCollateralETHAfterBorrow, , , , , uint256 healthFactorBeforeBorrow) =
          lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

        console.log('healthFactorBeforeBorrow', healthFactorBeforeBorrow / 1e27);
      }

      _borrowFromLendingPool(root.blockchain.eoaWallet, root.tokens.usdc, maxAvailableUsdcBorrows);

      uint256 usdcBalAfterBorrow = IERC20(root.tokens.usdc).balanceOf(root.blockchain.eoaWallet);
      console2.log('usdc bal after borrow', usdcBalAfterBorrow);

      (uint256 totalCollateralETHAfterBorrow, , , , , uint256 healthFactorAfterBorrow) =
        lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

      assertEq(
        usdcBalAfterBorrow,
        usdcBalBeforeBorrow + maxAvailableUsdcBorrows,
        'USDC balance increased after borrow'
      );

      console.log('b4 price manip HF', healthFactorAfterBorrow / 1e18);

      DataTypes.ReserveData memory rdUSDC = lendingPoolContract.getReserveData(root.tokens.usdc);
      DataTypes.ReserveData memory rdLPXSGD = lendingPoolContract.getReserveData(root.fxPool.xsgdUsdcFxp);

      address aaveOracle = ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPriceOracle();

      {
        uint256 usdcPrice = AaveOracle(aaveOracle).getAssetPrice(root.tokens.usdc);
        console.log('usdcPrice:', usdcPrice);
        MockAggregator manipulatedLPOracle = new MockAggregator(10_500, 8);

        address[] memory assets = new address[](1);
        assets[0] = root.tokens.usdc;
        address[] memory sources = new address[](1);
        sources[0] = address(manipulatedLPOracle);

        vm.prank(root.lendingPool.oracleOwner);
        // LP token Price manipulation is working
        AaveOracle(aaveOracle).setAssetSources(assets, sources);
      }

      {
        uint256 lpTokenPrice = AaveOracle(aaveOracle).getAssetPrice(root.fxPool.xsgdUsdcFxp);
        console.log('lpTokenPrice Before Manipulation:', lpTokenPrice);

        (, , , , , uint256 healthFactorBeforeManip) =
          lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

        console.log('HF before price manipulation', healthFactorBeforeManip / 1e18);
      }
      _manipulatePriceOracle(root.fxPool.xsgdUsdcFxp, 1, 18);
      

      // TODO: Manipulate price to make loan health of eoa wallet below 1
      {
        uint256 lpTokenPriceAfter = AaveOracle(aaveOracle).getAssetPrice(root.fxPool.xsgdUsdcFxp);
        console.log('lpTokenPriceAfter After Manipulation:', lpTokenPriceAfter);

        (, , , , , uint256 healthFactorAfterBorrowAfter) =
          lendingPoolContract.getUserAccountData(root.blockchain.eoaWallet);

        console.log('HF after price manipulation', healthFactorAfterBorrowAfter / 1e18);

      }

      _liquidatePosition(
        root.lendingPool.donor,
        root.blockchain.eoaWallet,
        root.fxPool.xsgdUsdcFxp,
        root.tokens.usdc,
        type(uint256).max,
        true
      );

      // Assert balance of donor to increase in LP token

      // Assert loan health and position of eoa wallet to decrease

      // vm.warp(block.timestamp + 31536000);
      // vm.startPrank(root.blockchain.eoaWallet);
      // IERC20(root.tokens.usdc).approve(root.lendingPool.lendingPoolProxy, type(uint256).max);

      // uint256 xsgdLpBalBeforeRepay = IERC20(root.fxPool.xsgdUsdcFxp).balanceOf(root.blockchain.eoaWallet);

      // lendingPoolContract.repay(
      //   root.tokens.usdc,
      //   maxAvailableUsdcBorrows - 200 * 1e6,
      //   2, // stablecoin borrowing
      //   root.blockchain.eoaWallet
      // );
      // vm.stopPrank();

      // // TODO: In sepolia, 0 healthFactor becomes very big number (underflow), how to deal with this?
      // // assertGt(healthFactorAfterBorrow, healthFactorBefore, 'Health factor increased after borrow');

      // assertGt(totalCollateralETHAfterBorrow, totalCollateralETHBefore, 'totalCollateralETHAfterBorrow increased');

      // assertGt(
      //   usdcBalAfterBorrow,
      //   IERC20(root.tokens.usdc).balanceOf(root.blockchain.eoaWallet),
      //   'USDC balance decreased after repay'
      // );

      // vm.startPrank(root.blockchain.eoaWallet);
      // lendingPoolContract.withdraw(root.fxPool.xsgdUsdcFxp, 200 * 1e18, root.blockchain.eoaWallet);
      // vm.stopPrank();

      // assertGt(
      //   IERC20(root.fxPool.xsgdUsdcFxp).balanceOf(root.blockchain.eoaWallet),
      //   xsgdLpBalBeforeRepay,
      //   'LP Token balance increased after withdraw'
      // );
    }
  }

  function _getTokenBalances(address receiver) private {
    vm.startPrank(root.faucets.usdcWhale);
    IERC20(root.tokens.usdc).transfer(receiver, 10_000 * 1e6);
    vm.stopPrank();

    vm.startPrank(root.faucets.xsgdWhale);
    IERC20(root.tokens.xsgd).transfer(receiver, 10_000 * 1e6);
    vm.stopPrank();

    _addLiquidity(
      IFXPool(root.fxPool.xsgdUsdcFxp).getPoolId(),
      1_000 * 1e18,
      receiver,
      root.tokens.usdc,
      root.tokens.xsgd
    );
  }

  function _getLendingPoolAccountData(address user) private returns (uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor){
    (uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor) = lendingPoolContract.getUserAccountData(user);
  }

  function _getReservesData() private {
    (IHaloUiPoolDataProvider.AggregatedReserveData[] memory reservesData, ) =
          IHaloUiPoolDataProvider(root.lendingPool.uiDataProvider).getReservesData(
            ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider)
          );
        console2.log('reservesData.length', reservesData.length);
        for (uint256 i = 0; i < reservesData.length; i++) {
          if (reservesData[i].underlyingAsset == root.fxPool.xsgdUsdcFxp)
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

  function _manipulatePriceOracle(address asset, int256 price, uint8 decimals) private {
    address aaveOracle = ILendingPoolAddressesProvider(root.lendingPool.lendingAddressProvider).getPriceOracle();
    MockAggregator manipulatedLPOracle = new MockAggregator(price, decimals);

    address[] memory assets = new address[](1);
    assets[0] = asset;
    address[] memory sources = new address[](1);
    sources[0] = address(manipulatedLPOracle);

    vm.prank(root.lendingPool.oracleOwner);
    AaveOracle(aaveOracle).setAssetSources(assets, sources);
  }

  function _liquidatePosition(address liquidator, address liquidatee, address collateralToken, address paymentToken, uint256 amount, bool inATokens) private {
    vm.startPrank(liquidator);
    IERC20(root.tokens.usdc).approve(root.lendingPool.lendingPoolProxy, type(uint256).max);
    lendingPoolContract.liquidationCall(
      collateralToken,
      paymentToken,
      liquidatee,
      amount,
      inATokens
    );
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

  /** *High Priority*
  // TODO: Test WETH gateway for AVAX chain?
  // Invoke WETHGateway.depositETH() check (technically its WAVAX or W-MATIC)
   */

  /** *Low Priority*
  TODO: Add repay test if it improve health factor
  - User pov (done)
  - Lending pool pov

   */

  /**
   In future, Test incentive emission?
    */

  function _addLiquidity(
    bytes32 _poolId,
    uint256 _depositNumeraire,
    address _user,
    address _tA,
    address _tB
  ) private {
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

    IVault.JoinPoolRequest memory reqJoin =
      IVault.JoinPoolRequest(_asIAsset(assets), maxAmountsIn, userDataJoin, false);

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
  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external payable;

  struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
      IERC20[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
    );
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

interface ILendingPoolAddressesProviderWithOwner is ILendingPoolAddressesProvider {
  function owner() external view returns (address);
}
