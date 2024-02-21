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

import {FXEthPriceFeedOracle} from '../contracts/xave-oracles/FXEthPriceFeedOracle.sol';

import {OpsConfigHelper, IOpsTestData} from './helpers/OpsConfigHelper.sol';

import '../contracts/xave-oracles/libraries/ABDKMath64x64.sol';

contract LendingMarketOpsTestAdmin is Test, OpsConfigHelper {
  using ABDKMath64x64 for int128;
  using ABDKMath64x64 for int256;
  using ABDKMath64x64 for uint256;
  //// network dependent config
  //// only the following lines are needed to be changed for different networks
  string private NETWORK = 'polygon';
  string private RPC_URL = vm.envString('POLYGON_RPC_URL');
  uint256 constant FORK_BLOCK = 52764552;
  address constant LENDINPOOL_PROXY_ADDRESS = 0x78a5B2B028Fa6Fb0862b0961EB5131C95273763B;
  address constant LENDINGPOOL_ADDRESS_PROVIDER = 0x68aeB9C8775Cfc9b99753A1323D532556675c555;
  address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  //// network dependent config end

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);
  }

  function testLendingMarketAddresses() public {
    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);
    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));
    // assertEq(root.lendingPool.admin, lpAddrProvider.getPoolAdmin(), 'correct pool admin set');

    // assertEq(root.lendingPool.poolAddress, lpAddrProvider.getLendingPool(), 'correct lending pool set');
    console.log('lpAddrProvider.getLendingPoolConfigurator():', lpAddrProvider.getLendingPoolConfigurator());
    console.log('root.lendingPool.poolConfigurator:', root.lendingPool.poolConfigurator);
    // assertEq(
    //   lpAddrProvider.getLendingPoolConfigurator(),
    //   root.lendingPool.poolConfigurator,
    //   'correct lending pool configurator set'
    // );
    // assertEq(
    //   root.lendingPool.collateralManager,
    //   lpAddrProvider.getLendingPoolCollateralManager(),
    //   'correct lending pool collateral manager set'
    // );
    // assertEq(root.lendingPool.emergencyAdmin, lpAddrProvider.getEmergencyAdmin(), 'correct emergency admin set');
    // assertEq(root.lendingPool.priceOracle, lpAddrProvider.getPriceOracle(), 'correct price oracle set');
    // assertEq(
    //   root.lendingPool.lendingRateOracle,
    //   lpAddrProvider.getLendingRateOracle(),
    //   'correct lending rate oracle set'
    // );
  }

  // TODO: Check hardhat tests to ensure we are checking most of all post-deployment asserts and make sure deployment went perfect

  /**
  TODO:
   - Admin operations
   - Replace oracle
   - Deploy new oracle and set LP to use new oracle
   */

  function testAddNewReserve() public {
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));
    // Put this in JSON
    address LP_XSGD = 0xE6D8FcD23eD4e417d7e9D1195eDf2cA634684e0E;

    // Deploy reserve
    _deployReserve();

    // TODO: Query this from FX Pool value so value is dynamic when we use this test in different network

    (IERC20[] memory tokens, , ) =
      IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8).getPoolTokens(IFXPool(LP_XSGD).getPoolId());

    address baseAssimilator = IFXPool(LP_XSGD).assimilator(address(tokens[0]));
    address quoteAssimilator = IFXPool(LP_XSGD).assimilator(address(tokens[1]));

    // Set Oracle for asset
    address lpOracle = _deployOracle(LP_XSGD, baseAssimilator, quoteAssimilator);

    // Set oracle source for asset
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();

    address[] memory assets = new address[](1);
    assets[0] = LP_XSGD;
    address[] memory sources = new address[](1);
    sources[0] = address(lpOracle);

    vm.expectRevert(bytes('Ownable: caller is not the owner'));
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    address oracleOwner = AaveOracle(aaveOracle).owner();
    // address oracleOwner = root.lendingPool.oracleOwner;
    // console.log("oracleOwner:", oracleOwner);
    vm.prank(oracleOwner);
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    uint256 _price = AaveOracle(aaveOracle).getAssetPrice(LP_XSGD);

    // testConfigureReserveAsCollateral
    address lendingPoolConfigurator =
      ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator();

    // uint256 ltv = 8000;
    // uint256 liquidationThreshold = 8500;
    // uint256 LIQUIDATION_BONUS = 10500;
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    LendingPoolConfigurator(lendingPoolConfigurator).configureReserveAsCollateral(
      LP_XSGD,
      8000,
      8500,
      10500
    );

    address poolAdmin = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPoolAdmin();

    vm.startPrank(poolAdmin);

    LendingPoolConfigurator(lendingPoolConfigurator).configureReserveAsCollateral(
      LP_XSGD,
      8000,
      8500,
      10500
    );
    vm.stopPrank();
  }

  function testLendingPoolPauseAndUnpause() public {
    // TODO: Add admin ops calls and authorization checks
    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));
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
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));

    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);

    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    console.log('root.reserves.usdc:', root.reserves.usdc);

    // enableBorrowingOnReserve
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.enableBorrowingOnReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C, true);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.enableBorrowingOnReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C, true);
    vm.stopPrank();

    bool usdcBorrowIsEnabled =
      ((lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C)).data & (1 << 58)) != 0;
    assertEq(usdcBorrowIsEnabled, true, 'USDC borrowing enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.disableBorrowingOnReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.disableBorrowingOnReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration =
      lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    assertEq(
      (((lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C)).data & (1 << 58)) != 0), // bit 58: borrowing is enabled
      false,
      'USDC borrowing disabled'
    );
  }

  function testActivateAndDeactivateReserve() public {
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));

    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);

    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    console.log('root.reserves.usdc:', root.reserves.usdc);

    // enableBorrowingOnReserve
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.activateReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.activateReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);
    vm.stopPrank();

    bool usdcReserveActive =
      ((lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C)).data & (1 << 56)) != 0;
    assertEq(usdcReserveActive, true, 'USDC borrowing enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.deactivateReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    // Will fail because [FAIL. Reason: revert: Cannot call fallback function from the proxy admin]
    vm.expectRevert(); // TODO: Remove once there is a fallback reserve
    lpc.deactivateReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);
    // vm.expectEmit();
    vm.stopPrank();

    // DataTypes.ReserveConfigurationMap memory usdcConfiguration =
    //   lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    // assertEq(
    //   (((lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C)).data & (1 << 56)) != 0), // bit 56: Reserve is active
    //   false,
    //   'USDC reserve deactivated'
    // );
  }

  function testFreezeAndUnfreezeReserve() public {
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));

    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);

    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    console.log('root.reserves.usdc:', root.reserves.usdc);

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.freezeReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.freezeReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);
    vm.stopPrank();

    // bit 57: reserve is frozen
    bool isFrozen = ((lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C)).data & (1 << 57)) != 0;
    assertEq(isFrozen, true, 'USDC reserve frozen');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.unfreezeReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.unfreezeReserve(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration =
      lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    assertEq(
      (((lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C)).data & (1 << 57)) != 0), // bit 57: reserve is frozen
      false,
      'USDC reserve unfroze'
    );
  }

  function testEnableAndDisableReserveStableRate() public {
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));

    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);

    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.enableReserveStableRate(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.enableReserveStableRate(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);
    vm.stopPrank();

    // bit 59: stable rate borrowing enabled
    bool isFrozen = ((lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C)).data & (1 << 59)) != 0;
    assertEq(isFrozen, true, 'USDC stable rate enabled');

    // Expect to fail if msg.sender is not poolAdmin
    vm.expectRevert(bytes(Errors.CALLER_NOT_POOL_ADMIN));
    lpc.disableReserveStableRate(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    vm.startPrank(lpAddrProvider.getPoolAdmin());
    lpc.disableReserveStableRate(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);
    // vm.expectEmit();
    vm.stopPrank();

    DataTypes.ReserveConfigurationMap memory usdcConfiguration =
      lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C);

    assertEq(
      (((lendingPool.getConfiguration(0x2eB4157CeFeb13C6E38035A11244E19BC396e97C)).data & (1 << 59)) != 0), // bit 59: stable rate borrowing enabled
      false,
      'USDC stable rate disabled'
    );
  }

  function testPoolConfiguratorOperations() public {
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));

    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);

    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());

    // updateAToken

    // updateStableDebtToken

    // updateVariableDebtToken

    // configureReserveAsCollateral

    // setReserveFactor

    // setReserveInterestRateStrategyAddress
  }

  function _deployReserve() private {
    address LP_XSGD = 0xE6D8FcD23eD4e417d7e9D1195eDf2cA634684e0E;
    address XAVE_TREASURY = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;

    // Deploy Aave Tokens
    ILendingPool LP = ILendingPool(LENDINPOOL_PROXY_ADDRESS);
    AToken aToken = new AToken();
    aToken.initialize(
      LP,
      XAVE_TREASURY,
      LP_XSGD,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(LP_XSGD).decimals(),
      'aXSGD-USDC',
      'aXSGD-USDC',
      bytes('')
    );

    StableDebtToken sdt = new StableDebtToken();
    sdt.initialize(
      LP,
      LP_XSGD,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(LP_XSGD).decimals(),
      'sbtXSGD-USDC',
      'sbtXSGD-USDC',
      bytes('')
    );
    VariableDebtToken vdt = new VariableDebtToken();

    vdt.initialize(
      LP,
      LP_XSGD,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(LP_XSGD).decimals(),
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
      underlyingAssetDecimals: IERC20Detailed(LP_XSGD).decimals(),
      interestRateStrategyAddress: address(dris),
      underlyingAsset: LP_XSGD,
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
        0xBA12222222228d8Ba445958a75a0704d566BF2C8, // Balancer Vault
        baseAssim,
        quoteAssim
      );

    return address(lpOracle);
  }

  function testAdminOracleOperations() public {
    // AaveOracle(aaveOracle).setAssetSources(assets, sources);
  }

  function testLPUserOperations() public {
    address XSGD = 0xDC3326e71D45186F113a2F448984CA0e8D201995;
    address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address LP_XSGD = 0xE6D8FcD23eD4e417d7e9D1195eDf2cA634684e0E;

    address lp = 0x1B736B89cd70Cf355d71f55E626Dc53E8D56Bc2E;

    vm.startPrank(0xf89d7b9c864f589bbF53a82105107622B35EaA40); // USDC_HOLDER
    IERC20(USDC).transfer(lp, 10_000 * 1e6);
    vm.stopPrank();

    vm.startPrank(0x728C6f69B4EaB57A9f2dE0Cf8Fd170eE5f22Eb21); // XSGD_HOLDER
    IERC20(XSGD).transfer(lp, 10_000 * 1e6);
    vm.stopPrank();

    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 1_000 * 1e18, lp, USDC, XSGD);
    // TODO: Determine ETH amount using chainlink oracle price feed (check _loopSwapsExact)
    // uint256 depositAmountInEth = _convertToRawAmount(1_000 * 1e18, "Pass assim");

    ILendingPool LP = ILendingPool(LENDINPOOL_PROXY_ADDRESS);
    testAddNewReserve();

    (
      uint256 totalCollateralETHBefore,
      ,
      ,
      ,
      ,
      uint256 healthFactorBefore
    ) = LP.getUserAccountData(lp);

    console.log('totalCollateralETHBefore:', totalCollateralETHBefore);
    console.log('healthFactorBefore:', healthFactorBefore);

    vm.startPrank(lp);
    /** *Medium priority*
    // TODO: Add deposit tests
    1. User deposits LP Token and use as collateral
    - check user balance, borrow health factor,
    - check lending pool balance
   */
    IERC20(LP_XSGD).approve(LENDINPOOL_PROXY_ADDRESS, type(uint256).max);
    LP.deposit(
      LP_XSGD,
      1000 * 1e18,
      lp,
      0 // referral code
    );

    (
      uint256 totalCollateralETHAfter,
      ,
      ,
      ,
      ,
      uint256 healthFactorAfter
    ) = LP.getUserAccountData(lp);

    console.log('totalCollateralETHAfter:', totalCollateralETHAfter);
    console.log('healthFactorAfter:', healthFactorAfter);

    // Assert totalCollateralETHAfter is increased by 1000 * 1e18
    assertEq(totalCollateralETHAfter, totalCollateralETHBefore + 1000 * 1e18, 'totalCollateralETHAfter increased');

    vm.stopPrank();
  }

  /** *High Priority*
  // TODO: Test WETH gateway for AVAX chain?
  // Invoke WETHGateway.depositETH() check (technically its WAVAX or W-MATIC)
   */

  /** *High Priority*
    TODO: Check addresses if matches set configuration defined in Reserve Config (strategy)
    - Assert reserves configurations if matching JSON for network file
    TODO: Check owners of deployed contracts
    */

  /** *Medium priority*
    // TODO: Add borrowing tests against stablecoin (USDC) using deposited LP Token as collateral
    - check maximum allowable borrow amount if equates to set LTV for collateral asset matches strategy defined
    - check user balance, borrow health factor after borrow
    - check lending pool balance after borrow
    */

  /** *Low Priority*
  TODO: Add repay test if it improve health factor
  - User pov
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
    address BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

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
    IERC20(_tA).approve(BALANCER_VAULT, type(uint256).max);
    IERC20(_tB).approve(BALANCER_VAULT, type(uint256).max);
    IVault(BALANCER_VAULT).joinPool(_poolId, _user, _user, reqJoin);
    vm.stopPrank();
  }

  function _asIAsset(address[] memory addresses) private pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      assets := addresses
    }
  }

  // function _convertToRawAmount(uint256 amount, address assimilator) private returns (uint256) {
  //   return IAssimilator(assimilator).viewRawAmount(ABDKMath64x64.fromUInt(amount));
  // }
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
