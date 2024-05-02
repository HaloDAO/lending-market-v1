// deploy FXLPEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import 'forge-std/console2.sol';

import {IERC20Detailed} from '../contracts/dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {FXLPEthPriceFeedOracle} from '../contracts/xave-oracles/FXLPEthPriceFeedOracle.sol';
import {LendingPoolAddressesProviderRegistry} from '../contracts/protocol/configuration/LendingPoolAddressesProviderRegistry.sol';
import {LendingPoolAddressesProvider} from '../contracts/protocol/configuration/LendingPoolAddressesProvider.sol';
import {LendingPoolConfigurator} from '../contracts/protocol/lendingpool/LendingPoolConfigurator.sol';
import {LendingPool} from '../contracts/protocol/lendingpool/LendingPool.sol';
import {ILendingPool} from '../contracts/interfaces/ILendingPool.sol';

import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';

import {StableAndVariableTokensHelper} from '../contracts/deployments/StableAndVariableTokensHelper.sol';
import {ATokensAndRatesHelper} from '../contracts/deployments/ATokensAndRatesHelper.sol';
import {AToken} from '../contracts/protocol/tokenization/AToken.sol';
import {VariableDebtToken} from '../contracts/protocol/tokenization/VariableDebtToken.sol';
import {StableDebtToken} from '../contracts/protocol/tokenization/StableDebtToken.sol';
import {DefaultReserveInterestRateStrategy} from '../contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {IAaveIncentivesController} from '../contracts/interfaces/IAaveIncentivesController.sol';
import {AaveOracle} from '../contracts/misc/AaveOracle.sol';
import {WalletBalanceProvider} from 'contracts/misc/WalletBalanceProvider.sol';
import {LendingRateOracle} from '../contracts/mocks/oracle/LendingRateOracle.sol';
import {IDeploymentLendingMarketConfig} from './interfaces/IDeploymentLendingMarketConfig.sol';
import {DeploymentConfigHelper} from './helpers/DeploymentConfigHelper.sol';
import {AaveProtocolDataProvider} from '../contracts/misc/AaveProtocolDataProvider.sol';
import {ILendingPoolConfigurator} from '../contracts/interfaces/ILendingPoolConfigurator.sol';
import {LendingPoolCollateralManager} from '../contracts/protocol/lendingpool/LendingPoolCollateralManager.sol';
import {UiHaloPoolDataProvider} from '../contracts/misc/UiHaloPoolDataProvider.sol';
import {UiIncentiveDataProvider} from '../contracts/misc/UiIncentiveDataProvider.sol';
import {IChainlinkAggregator} from '../contracts/interfaces/IChainlinkAggregator.sol';
import {DataTypes} from '../contracts/protocol/libraries/types/DataTypes.sol';
import {IAToken} from '../contracts/interfaces/IAToken.sol';
import {ReserveConfiguration} from '../contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

contract LendingPoolAddNewAsset is Script, DeploymentConfigHelper {
  using stdJson for string;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  address constant treasury = 0x009c4ba01488A15816093F96BA91210494E2C644;
  address constant poolAdmin = 0x009c4ba01488A15816093F96BA91210494E2C644;
  address constant LendingPoolAddressProviderAddress = 0xde29585a4134752632a07f09BCA0f02F72a33B8d;
  address constant stableVarHelperAddress = 0x8b661A0A273EC235e9935793692b42E9C3487164;
  address constant aTokensHelperAddress = 0x79DD0b8b83C4FB4f66e90F33139b002eb2b268f3;
  address constant aaveOracleAddress = 0x972127aFf8e6464e50eFc0a2aD344063355AE424;
  address constant incentivesController = address(0); // @todo

  DataTypes.ReserveData private _reserveData;

  function run(string memory network) external {
    vm.startBroadcast(0x235A2ac113014F9dcb8aBA6577F20290832dDEFd);
    console2.log('Broadcasting transactions..');
    _execute(network);
    vm.stopBroadcast();
  }

  function _execute(string memory network) private {
    IDeploymentLendingMarketConfig.Token memory c = _readDeploymentLendingMarketTokenConfig(
      string(abi.encodePacked('new-assets/', network, '/usdt.json'))
    );

    LendingPoolAddressesProvider addressProvider = LendingPoolAddressesProvider(LendingPoolAddressProviderAddress);
    console2.log(addressProvider.getPoolAdmin());
    _setOracles(c);
    _initReservesByHelper(c, addressProvider);
    _configureReservesByHelper(c, ATokensAndRatesHelper(aTokensHelperAddress), addressProvider);
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
    console2.log('Atokens deployed : ', address(a));
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
    console2.log('Sdt deployed : ', address(sdt));
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

    console2.log('Vdt deployed : ', address(vdt));

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

    console.log('sender', msg.sender);
    console.log(addressProvider.getPoolAdmin());
    console.log(_aTokensHelper.owner());
    console.log('set pool admin to atokens helper');

    addressProvider.setPoolAdmin(address(_aTokensHelper));
    console.log('Configuring reserves');
    _aTokensHelper.configureReserves(inputParams);
    addressProvider.setPoolAdmin(0x235A2ac113014F9dcb8aBA6577F20290832dDEFd);
  }
}
