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
import {
  DefaultReserveInterestRateStrategy
} from '../contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {IAaveIncentivesController} from '../contracts/interfaces/IAaveIncentivesController.sol';
// import {UpdateATokenInput, UpdateDebtTokenInput } from '../contracts/interfaces/ILendingPoolConfigurator.sol';

import {FXEthPriceFeedOracle} from '../contracts/xave-oracles/FXEthPriceFeedOracle.sol';

import {OpsConfigHelper, IOpsTestData} from './helpers/OpsConfigHelper.sol';

// forge test -w -vv --match-path test/SepoliaLendingMarketOpsTestAdmin.t.sol
contract SepoliaLendingMarketOpsTestAdmin is Test, OpsConfigHelper {
  //// network dependent config
  //// only the following lines are needed to be changed for different networks
  string private NETWORK = 'sepolia';
  string private RPC_URL = vm.envString('SEPOLIA_RPC_URL');
  uint256 constant FORK_BLOCK = 5339189; // Thinking to put inside json
  address constant LENDINPOOL_PROXY_ADDRESS = 0xe2E56CA629fF578b89E5be2F9d7CD68A5F9Aa51d; // Thinking to put inside json
  address constant LENDINGPOOL_ADDRESS_PROVIDER = 0x0F717741C11165B9588350852b856858Bf221D84; // Thinking to put inside json
  address constant lp = 0x18f7A91DD8B6593744Ef7aBcD19B7Dc07f21d8d9; // Thinking to put inside json
  //// network dependent config end

  IOpsTestData.Root root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));
  ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);
  }

  function testLendingMarketAddresses() public {
    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    assertEq(root.lendingPool.admin, lpAddrProvider.getPoolAdmin(), 'correct pool admin set');

    assertEq(root.lendingPool.poolAddress, lpAddrProvider.getLendingPool(), 'correct lending pool set');

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
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();

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
    address lendingPoolConfigurator =
      ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator();

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    LendingPoolConfigurator(lendingPoolConfigurator).configureReserveAsCollateral(
      root.fxPool.xsgdUsdcFxp,
      root.reserveConfigs.lpXsgdUsdc.baseLtv,
      root.reserveConfigs.lpXsgdUsdc.liquidationBonus,
      root.reserveConfigs.lpXsgdUsdc.liquidationThreshold
    );

    address poolAdmin = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPoolAdmin();

    vm.startPrank(poolAdmin);

    LendingPoolConfigurator(lendingPoolConfigurator).configureReserveAsCollateral(
      root.fxPool.xsgdUsdcFxp,
      root.reserveConfigs.lpXsgdUsdc.baseLtv,
      root.reserveConfigs.lpXsgdUsdc.liquidationBonus,
      root.reserveConfigs.lpXsgdUsdc.liquidationThreshold
    );
    vm.stopPrank();
  }

  function testLendingPoolPauseAndUnpause() public {
    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    vm.expectRevert(bytes(Errors.LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR));
    lendingPool.setPause(true);

    // vm.startPrank(root.lendingPool.poolConfigurator);
    vm.startPrank(lpAddrProvider.getLendingPoolConfigurator());

    lendingPool.setPause(true);
    assertEq(lendingPool.paused(), true, 'reserve paused');
    lendingPool.setPause(false);
    assertEq(lendingPool.paused(), false, 'reserve unpaused');
    vm.stopPrank();
  }

  function testEnableAndDisableReserveBorrowing() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    // enableBorrowingOnReserve
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.enableBorrowingOnReserve(root.reserves.usdc, true);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.enableBorrowingOnReserve(root.reserves.usdc, true);
    vm.stopPrank();

    bool usdcBorrowIsEnabled = ((lendingPool.getConfiguration(root.reserves.usdc)).data & (1 << 58)) != 0;
    assertEq(usdcBorrowIsEnabled, true, 'USDC borrowing enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.disableBorrowingOnReserve(root.reserves.usdc);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.disableBorrowingOnReserve(root.reserves.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration = lendingPool.getConfiguration(root.reserves.usdc);

    assertEq(
      (((lendingPool.getConfiguration(root.reserves.usdc)).data & (1 << 58)) != 0), // bit 58: borrowing is enabled
      false,
      'USDC borrowing disabled'
    );
  }

  function testActivateAndDeactivateReserve() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    // enableBorrowingOnReserve
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.activateReserve(root.reserves.usdc);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.activateReserve(root.reserves.usdc);
    vm.stopPrank();

    bool usdcReserveActive = ((lendingPool.getConfiguration(root.reserves.usdc)).data & (1 << 56)) != 0;
    assertEq(usdcReserveActive, true, 'USDC borrowing enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.deactivateReserve(root.reserves.usdc);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    // Will fail because [FAIL. Reason: revert: Cannot call fallback function from the proxy admin]
    vm.expectRevert(); // TODO: Remove once there is a fallback reserve
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
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.freezeReserve(root.reserves.usdc);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.freezeReserve(root.reserves.usdc);
    vm.stopPrank();

    // bit 57: reserve is frozen
    bool isFrozen = ((lendingPool.getConfiguration(root.reserves.usdc)).data & (1 << 57)) != 0;
    assertEq(isFrozen, true, 'USDC reserve frozen');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.unfreezeReserve(root.reserves.usdc);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.unfreezeReserve(root.reserves.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration = lendingPool.getConfiguration(root.reserves.usdc);

    assertEq(
      (((lendingPool.getConfiguration(root.reserves.usdc)).data & (1 << 57)) != 0), // bit 57: reserve is frozen
      false,
      'USDC reserve unfroze'
    );
  }

  function testEnableAndDisableReserveStableRate() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.enableReserveStableRate(root.reserves.usdc);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.enableReserveStableRate(root.reserves.usdc);
    vm.stopPrank();

    // bit 59: stable rate borrowing enabled
    bool isFrozen = ((lendingPool.getConfiguration(root.reserves.usdc)).data & (1 << 59)) != 0;
    assertEq(isFrozen, true, 'USDC stable rate enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.disableReserveStableRate(root.reserves.usdc);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.disableReserveStableRate(root.reserves.usdc);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration = lendingPool.getConfiguration(root.reserves.usdc);

    assertEq(
      (((lendingPool.getConfiguration(root.reserves.usdc)).data & (1 << 59)) != 0), // bit 59: stable rate borrowing enabled
      false,
      'USDC stable rate disabled'
    );
  }

  function testSetReserveFactor() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.setReserveFactor(root.reserves.usdc, 0);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.setReserveFactor(root.reserves.usdc, 0);
    vm.stopPrank();

    // bit 64-79: reserve factor
  
    // Step 1: Shift the data to the right by 64 bits to position the reserve factor in bits 0-15
    uint256 shifted = (lendingPool.getConfiguration(root.reserves.usdc)).data >> 64;
    
    // Step 2: Apply the mask to isolate bits 0-15, which now contain the reserve factor
    uint256 reserveFactor = shifted & ((1 << 16) - 1);

    assertEq(reserveFactor, 0, 'USDC reserve factor set to 0');
  }

  function testSetReserveInterestRateStrategyAddress() public {
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.setReserveInterestRateStrategyAddress(root.reserves.usdc, 0x0000000000000000000000000000000000000000);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.setReserveInterestRateStrategyAddress(root.reserves.usdc, 0x0000000000000000000000000000000000000000);
    vm.stopPrank();

    DataTypes.ReserveData memory usdcReserveData = lendingPool.getReserveData(root.reserves.usdc);

    assertEq(usdcReserveData.interestRateStrategyAddress, 0x0000000000000000000000000000000000000000);
  }

  // function testUpdateATokens() public {
  //   LendingPoolConfigurator lpc =
  //     LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

  //   ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

  //   ILendingPoolConfigurator.UpdateATokenInput memory input = ILendingPoolConfigurator.UpdateATokenInput({
  //     asset: root.tokens.xsgd,
  //     treasury: root.fxPool.vault,
  //     incentivesController: address(0x0000000000000000000000000000000000000000),
  //     name: 'aXSGD',
  //     symbol: 'aXSGD',
  //     implementation: address(0x0000000000000000000000000000000000000000),
  //     params: bytes('0x')
  //   });

  //   vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
  //   lpc.updateStableDebtToken(input);

  //   vm.startPrank(lpAddrProvider.getPoolAdmin());
  //   lpc.setReserveInterestRateStrategyAddress(root.reserves.usdc, 0x0000000000000000000000000000000000000000);
  //   vm.stopPrank();

  //   DataTypes.ReserveData memory usdcReserveData = lendingPool.getReserveData(root.reserves.usdc);

  //   assertEq(usdcReserveData.interestRateStrategyAddress, 0x0000000000000000000000000000000000000000);
  // }

  function testPoolConfiguratorOperations() public {
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));

    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);

    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    // updateStableDebtToken

    // updateVariableDebtToken
  }

  function _deployReserve() private {
    address XAVE_TREASURY = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;

    // Deploy Aave Tokens
    AToken aToken = new AToken();
    aToken.initialize(
      lendingPool,
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
      lendingPool,
      root.fxPool.xsgdUsdcFxp,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(root.fxPool.xsgdUsdcFxp).decimals(),
      'sbtXSGD-USDC',
      'sbtXSGD-USDC',
      bytes('')
    );
    VariableDebtToken vdt = new VariableDebtToken();

    vdt.initialize(
      lendingPool,
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
        ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER),
        0.9 * 1e27, // optimal utilization rate
        0 * 1e27, // baseVariableBorrowRate
        0.04 * 1e27, // variableRateSlope1
        0.60 * 1e27, // variableRateSlope2
        0.02 * 1e27, // stableRateSlope1
        0.60 * 1e27 // stableRateSlope2
      );

    // Deploy Reserve
    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

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

    vm.prank(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPoolAdmin());
    lpc.batchInitReserve(input);
  }

  function _deployOracle(
    address asset,
    address baseAssim,
    address quoteAssim
  ) internal returns (address) {
    FXEthPriceFeedOracle lpOracle =
      new FXEthPriceFeedOracle(
        asset,
        0xF9680D99D6C9589e2a93a78A04A279e509205945, // ETH USD Oracle
        'LPXSGD-USDC/ETH',
        root.fxPool.vault, // Balancer Vault
        baseAssim,
        quoteAssim
      );

    return address(lpOracle);
  }

  function testLPUserOperations() public {
    vm.startPrank(root.faucets.usdcWhale);
    IERC20(root.tokens.usdc).transfer(lp, 10_000 * 1e6);
    vm.stopPrank();

    vm.startPrank(root.faucets.xsgdWhale);
    IERC20(root.tokens.xsgd).transfer(lp, 10_000 * 1e6);
    vm.stopPrank();

    console.log('b4 add liq');

    (IERC20[] memory tokens, , ) =
      IVault(root.fxPool.vault).getPoolTokens(IFXPool(root.fxPool.xsgdUsdcFxp).getPoolId());

    assertEq(address(tokens[0]), root.tokens.xsgd, '[0] token mismatch');
    assertEq(address(tokens[1]), root.tokens.usdc, '[1] token mismatch');

    _addLiquidity(IFXPool(root.fxPool.xsgdUsdcFxp).getPoolId(), 1_000 * 1e18, lp, root.tokens.usdc, root.tokens.xsgd);

    console.log('after add liq');

    (, int256 ethUsdPrice, , , ) = IOracle(root.chainlink.ethUsd).latestRoundData();
    (, int256 usdcUsdPrice, , , ) = IOracle(root.chainlink.usdcUsd).latestRoundData();

    _addNewReserve();

    (uint256 totalCollateralETHBefore, , , , , uint256 healthFactorBefore) = lendingPool.getUserAccountData(lp);

    console.log('totalCollateralETHBefore:', totalCollateralETHBefore);
    console.log('healthFactorBefore:', healthFactorBefore);

    vm.startPrank(lp);
    /** *Medium priority*
    // TODO: Add deposit tests
    1. User deposits LP Token and use as collateral
    - check user balance, borrow health factor,
    - check lending pool balance
   */
    IERC20(root.fxPool.xsgdUsdcFxp).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);
    lendingPool.deposit(
      root.fxPool.xsgdUsdcFxp,
      1000 * 1e18,
      lp,
      0 // referral code
    );

    {
      (uint256 totalCollateralETHAfterDeposit, , uint256 availableBorrowsETHAfter, , , uint256 healthFactorAfter) =
        lendingPool.getUserAccountData(lp);

      console.log('totalCollateralETHAfterDeposit:', totalCollateralETHAfterDeposit);
      console.log('healthFactorAfter:', healthFactorAfter);

      uint256 maxAvailableUsdcBorrows =
        (((availableBorrowsETHAfter * uint256(ethUsdPrice)) / uint256(usdcUsdPrice)) / 1e18);
      console.log('maxAvailableUsdcBorrows:', maxAvailableUsdcBorrows);

      uint256 usdcBalBeforeBorrow = IERC20(root.tokens.usdc).balanceOf(lp);

      lendingPool.borrow(
        root.tokens.usdc,
        maxAvailableUsdcBorrows,
        2, // stablecoin borrowing
        0, // referral code
        lp
      );

      uint256 usdcBalAfterBorrow = IERC20(root.tokens.usdc).balanceOf(lp);

      (uint256 totalCollateralETHAfterBorrow, , , , , uint256 healthFactorAfterBorrow) = lendingPool.getUserAccountData(lp);

      assertEq(
        usdcBalAfterBorrow,
        usdcBalBeforeBorrow + maxAvailableUsdcBorrows,
        'USDC balance increased after borrow'
      );

      vm.warp(block.timestamp + 31536000);
      IERC20(root.tokens.usdc).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);

      uint256 xsgdLpBalBeforeRepay = IERC20(root.fxPool.xsgdUsdcFxp).balanceOf(lp);

      lendingPool.repay(
        root.tokens.usdc,
        maxAvailableUsdcBorrows - 200 * 1e6,
        2, // stablecoin borrowing
        lp
      );

      assertGt(healthFactorAfterBorrow, healthFactorBefore, 'Health factor increased after borrow');

      assertGt(totalCollateralETHAfterBorrow, totalCollateralETHBefore, 'totalCollateralETHAfterBorrow increased');

      assertGt(usdcBalAfterBorrow, IERC20(root.tokens.usdc).balanceOf(lp), 'USDC balance decreased after repay');

      lendingPool.withdraw(root.fxPool.xsgdUsdcFxp, 200 * 1e18, lp);

      assertGt(
        IERC20(root.fxPool.xsgdUsdcFxp).balanceOf(lp),
        xsgdLpBalBeforeRepay,
        'LP Token balance increased after withdraw'
      );
    }
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
