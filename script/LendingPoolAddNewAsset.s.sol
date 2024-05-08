// deploy FXLPEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import 'forge-std/console2.sol';
import 'forge-std/Test.sol';

import {IERC20Detailed} from '../contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {FXLPEthPriceFeedOracle} from '../contracts/xave-oracles/FXLPEthPriceFeedOracle.sol';
import {LendingPoolAddressesProvider} from '../contracts/protocol/configuration/LendingPoolAddressesProvider.sol';
import {LendingPoolConfigurator} from '../contracts/protocol/lendingpool/LendingPoolConfigurator.sol';
import {LendingPool} from '../contracts/protocol/lendingpool/LendingPool.sol';
import {ILendingPool} from '../contracts/interfaces/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {ATokensAndRatesHelper} from '../contracts/deployments/ATokensAndRatesHelper.sol';
import {AToken} from '../contracts/protocol/tokenization/AToken.sol';
import {VariableDebtToken} from '../contracts/protocol/tokenization/VariableDebtToken.sol';
import {StableDebtToken} from '../contracts/protocol/tokenization/StableDebtToken.sol';
import {DefaultReserveInterestRateStrategy} from '../contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {IAaveIncentivesController} from '../contracts/interfaces/IAaveIncentivesController.sol';
import {AaveOracle} from '../contracts/misc/AaveOracle.sol';
import {IDeploymentLendingMarketConfig} from './interfaces/IDeploymentLendingMarketConfig.sol';
import {DeploymentConfigHelper} from './helpers/DeploymentConfigHelper.sol';
import {ILendingPoolConfigurator} from '../contracts/interfaces/ILendingPoolConfigurator.sol';
import {ReserveConfiguration} from '../contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from '../contracts/protocol/libraries/types/DataTypes.sol';

contract LendingPoolAddNewAsset is Script, DeploymentConfigHelper, Test {
  using stdJson for string;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  address constant treasury = 0x009c4ba01488A15816093F96BA91210494E2C644;
  address constant poolAdmin = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;
  address constant LendingPoolAddressProviderAddress = 0xde29585a4134752632a07f09BCA0f02F72a33B8d;
  address constant stableVarHelperAddress = 0x8b661A0A273EC235e9935793692b42E9C3487164;
  address constant aTokensHelperAddress = 0x79DD0b8b83C4FB4f66e90F33139b002eb2b268f3;
  address constant aaveOracleAddress = 0x972127aFf8e6464e50eFc0a2aD344063355AE424;
  address constant incentivesController = address(0); // @todo

  IDeploymentLendingMarketConfig.Token config;

  DataTypes.ReserveData private _reserveData;

  function run(string memory network) external {
    // script run
    vm.startBroadcast();
    console2.log('Broadcasting transactions..');
    _execute(network);

    vm.stopBroadcast();

    DataTypes.ReserveData memory newReserveData = ILendingPool(
      ILendingPoolAddressesProvider(LendingPoolAddressProviderAddress).getLendingPool()
    ).getReserveData(config.addr);

    console2.log('~~~~~~~~~ POST DEPLOYMENT INFO ~~~~~~~~~');
    console.log('aTokenAddress: ', newReserveData.aTokenAddress);
    console.log('stableDebtTokenAddress: ', newReserveData.stableDebtTokenAddress);
    console.log('variableDebtTokenAddress: ', newReserveData.variableDebtTokenAddress);
    console.log('interestRateStrategyAddress: ', newReserveData.interestRateStrategyAddress);

    // tests
    vm.startPrank(poolAdmin);
    _testLendingPool(config);
    vm.stopPrank();
  }

  function _execute(string memory network) private {
    config = _readDeploymentLendingMarketTokenConfig(string(abi.encodePacked('new-assets/', network, '/usdt.json')));
    vm.label(config.addr, 'usdt');
    LendingPoolAddressesProvider addressProvider = LendingPoolAddressesProvider(LendingPoolAddressProviderAddress);
    _setOracles(config);
    _initReservesByHelper(config, addressProvider);
    _configureReservesByHelper(config, ATokensAndRatesHelper(aTokensHelperAddress), addressProvider);
  }

  function _setOracles(IDeploymentLendingMarketConfig.Token memory c) private {
    AaveOracle oracle = AaveOracle(aaveOracleAddress);
    address[] memory assetAddresses = new address[](1);
    address[] memory assetOracleAddresses = new address[](1);

    assetAddresses[0] = c.addr;

    assetOracleAddresses[0] = c.chainlinkAggregator.aggregator;
    console2.log('setting oracles');

    oracle.setAssetSources(assetAddresses, assetOracleAddresses);
    console2.log('oracles set');
  }

  function _deployAaveTokens(
    address _lendingPoolProxy,
    IDeploymentLendingMarketConfig.Token memory c
  ) private returns (AToken, StableDebtToken, VariableDebtToken) {
    console2.log('deploying atokens for', c.addr);
    AToken a = new AToken();

    a.initialize(
      ILendingPool(_lendingPoolProxy),
      treasury,
      c.addr,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(c.addr).decimals(),
      string(abi.encodePacked('x', c.rateStrategy.tokenReserve)),
      string(abi.encodePacked('x', c.rateStrategy.tokenReserve)),
      bytes('')
    );

    console2.log('deploying stableDebt for ', c.addr);

    StableDebtToken sdt = new StableDebtToken();
    sdt.initialize(
      ILendingPool(_lendingPoolProxy),
      c.addr,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(c.addr).decimals(),
      string(abi.encodePacked('xsbt', c.rateStrategy.tokenReserve)),
      string(abi.encodePacked('xsbt', c.rateStrategy.tokenReserve)),
      bytes('')
    );
    console2.log('deploying variableDebt for ', c.addr);
    VariableDebtToken vdt = new VariableDebtToken();
    vdt.initialize(
      ILendingPool(_lendingPoolProxy),
      c.addr,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(c.addr).decimals(),
      string(abi.encodePacked('xvdt', c.rateStrategy.tokenReserve)),
      string(abi.encodePacked('xvdt', c.rateStrategy.tokenReserve)),
      bytes('')
    );
    return (a, sdt, vdt);
  }

  function _initReservesByHelper(
    IDeploymentLendingMarketConfig.Token memory c,
    LendingPoolAddressesProvider _addressProvider
  ) private {
    console.log('deploying aave tokens');

    (AToken aToken, StableDebtToken sdToken, VariableDebtToken vdToken) = _deployAaveTokens(
      _addressProvider.getLendingPool(),
      c
    );

    console.log('aave tokens deployed');
    LendingPoolConfigurator cfg = LendingPoolConfigurator(_addressProvider.getLendingPoolConfigurator());

    DefaultReserveInterestRateStrategy strategy = new DefaultReserveInterestRateStrategy(
      _addressProvider,
      c.rateStrategy.optimalUtilizationRate,
      c.rateStrategy.baseVariableBorrowRate,
      c.rateStrategy.variableRateSlope1,
      c.rateStrategy.variableRateSlope2,
      c.rateStrategy.stableRateSlope1,
      c.rateStrategy.stableRateSlope2
    );

    ILendingPoolConfigurator.InitReserveInput[] memory cfgInput = new ILendingPoolConfigurator.InitReserveInput[](1);

    cfgInput[0] = ILendingPoolConfigurator.InitReserveInput({
      aTokenImpl: address(aToken),
      stableDebtTokenImpl: address(sdToken),
      variableDebtTokenImpl: address(vdToken),
      underlyingAssetDecimals: IERC20Detailed(c.addr).decimals(),
      interestRateStrategyAddress: address(strategy),
      underlyingAsset: c.addr,
      treasury: treasury,
      incentivesController: incentivesController,
      underlyingAssetName: c.rateStrategy.tokenReserve,
      aTokenName: aToken.name(),
      aTokenSymbol: aToken.symbol(),
      variableDebtTokenName: vdToken.name(),
      variableDebtTokenSymbol: vdToken.symbol(),
      stableDebtTokenName: sdToken.name(),
      stableDebtTokenSymbol: sdToken.symbol(),
      params: bytes('')
    });

    console.log('Initializing reserve');
    cfg.batchInitReserve(cfgInput);
  }

  function _configureReservesByHelper(
    IDeploymentLendingMarketConfig.Token memory _c,
    ATokensAndRatesHelper _aTokensHelper,
    LendingPoolAddressesProvider addressProvider
  ) private {
    ATokensAndRatesHelper.ConfigureReserveInput[]
      memory inputParams = new ATokensAndRatesHelper.ConfigureReserveInput[](1);

    inputParams[0] = ATokensAndRatesHelper.ConfigureReserveInput({
      asset: _c.addr,
      baseLTV: _c.reserveConfig.baseLTVAsCollateral,
      liquidationThreshold: _c.reserveConfig.liquidationThreshold,
      liquidationBonus: _c.reserveConfig.liquidationBonus,
      reserveFactor: _c.reserveConfig.reserveFactor,
      stableBorrowingEnabled: _c.reserveConfig.stableBorrowRateEnabled,
      borrowingEnabled: _c.reserveConfig.borrowingEnabled
    });

    console.log('set pool admin to atokens helper');

    addressProvider.setPoolAdmin(address(_aTokensHelper));
    console.log('Configuring reserves');
    _aTokensHelper.configureReserves(inputParams);
    addressProvider.setPoolAdmin(poolAdmin);
  }

  function _testLendingPool(IDeploymentLendingMarketConfig.Token memory c) private {
    address lendingPoolAddress = ILendingPoolAddressesProvider(LendingPoolAddressProviderAddress).getLendingPool();
    address usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    vm.label(lendingPoolAddress, 'lendingPool');

    DataTypes.ReserveData memory rd = ILendingPool(lendingPoolAddress).getReserveData(c.addr);
    DataTypes.ReserveData memory rd_borrowed = ILendingPool(lendingPoolAddress).getReserveData(usdc);

    console.log('~~~~~~~~~ Testing Lending Market Functions ~~~~~~~~~ ');
    IERC20Detailed(c.addr).approve(lendingPoolAddress, 5e6);
    console.log('depositing..');
    ILendingPool(lendingPoolAddress).deposit(c.addr, 5e6, poolAdmin, 0);
    assertLt(0, IERC20Detailed(rd.aTokenAddress).balanceOf(poolAdmin));

    console.log('borrowing usdc..');
    ILendingPool(lendingPoolAddress).borrow(usdc, 1e6, 2, 0, poolAdmin);
    assertLt(0, IERC20Detailed(rd_borrowed.variableDebtTokenAddress).balanceOf(poolAdmin));

    console.log('repaying..');
    IERC20Detailed(usdc).approve(lendingPoolAddress, 1e6);
    ILendingPool(lendingPoolAddress).repay(usdc, 1e6, 2, poolAdmin);
    assertEq(0, IERC20Detailed(rd_borrowed.variableDebtTokenAddress).balanceOf(poolAdmin));

    uint256 balanceBeforeWithdraw = IERC20Detailed(c.addr).balanceOf(poolAdmin);
    console.log('withdrawing..');
    ILendingPool(lendingPoolAddress).withdraw(c.addr, 3e6, poolAdmin);
    assertLt(balanceBeforeWithdraw, IERC20Detailed(c.addr).balanceOf(poolAdmin));

    console.log('~~~~~~~~~ Testing Borrowing new asset given USDC as collateral ~~~~~~~~~ ');
    IERC20Detailed(usdc).approve(lendingPoolAddress, 5e6);

    console.log('depositing..');
    ILendingPool(lendingPoolAddress).deposit(usdc, 5e6, poolAdmin, 0);

    console.log('borrowing usdt..');
    ILendingPool(lendingPoolAddress).borrow(c.addr, 1e6, 2, 0, poolAdmin);
    assertLt(0, IERC20Detailed(rd.variableDebtTokenAddress).balanceOf(poolAdmin));

    IERC20Detailed(c.addr).approve(lendingPoolAddress, 1e6);
    console.log('repaying..');
    ILendingPool(lendingPoolAddress).repay(c.addr, 1e6, 2, poolAdmin);
    assertEq(0, IERC20Detailed(rd.variableDebtTokenAddress).balanceOf(poolAdmin));

    console.log('~~~~~~~~~ Testing Complete! 🥹 ~~~~~~~~~ ');
  }
}
