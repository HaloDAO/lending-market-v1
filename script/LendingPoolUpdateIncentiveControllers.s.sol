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

// @note LendingPoolAddNewAsset
// @note LendingPoolUpdateAaveTokens / Update incentives controller
contract LendingPoolAddNewAsset is Script, DeploymentConfigHelper {
  using stdJson for string;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  address constant treasury = 0x009c4ba01488A15816093F96BA91210494E2C644;
  address constant poolAdmin = 0x009c4ba01488A15816093F96BA91210494E2C644; // @todo change
  address constant lendingPoolAddressProviderAddress = 0xde29585a4134752632a07f09BCA0f02F72a33B8d;
  address constant aaveOracleAddress = 0x972127aFf8e6464e50eFc0a2aD344063355AE424;
  address constant incentivesController = address(0); // @todo change
  address constant assetAddress = address(0); // @todo change
  address constant assetOracleAddress = address(0); // @todo change
  address constant aTokenAddress = address(0); // @todo change
  address constant sdtAddress = address(0); // @todo change
  address constant vdtAddress = address(0); // @todo change
  address constant aTokenImplAddress = address(0); // @todo change

  function run(string memory network) external {
    vm.startBroadcast();
    console2.log('Broadcasting transactions..');
    _execute(network);
    vm.stopBroadcast();
  }

  function _execute(string memory network) private {
    IDeploymentLendingMarketConfig.Token memory c = _readDeploymentLendingMarketTokenConfig(
      string(abi.encodePacked('new-assets/', network, '/usdt.json')) // @todo change, make a new json?
    );

    LendingPoolAddressesProvider addressProvider = LendingPoolAddressesProvider(lendingPoolAddressProviderAddress);
    address configuratorProxy = addressProvider.getLendingPoolConfigurator();
    LendingPoolConfigurator lpc = LendingPoolConfigurator(configuratorProxy);

    ILendingPoolConfigurator.UpdateATokenInput memory atokenInput = ILendingPoolConfigurator.UpdateATokenInput({
      asset: c.addr,
      treasury: treasury,
      incentivesController: incentivesController,
      name: string(abi.encodePacked('x', c.rateStrategy.tokenReserve)),
      symbol: string(abi.encodePacked('x', c.rateStrategy.tokenReserve)),
      implementation: aTokenImplAddress,
      params: bytes('')
    });

    ILendingPoolConfigurator.UpdateDebtTokenInput memory sdbtokenInput = ILendingPoolConfigurator.UpdateDebtTokenInput({
      asset: c.addr,
      incentivesController: incentivesController,
      name: string(abi.encodePacked('x', c.rateStrategy.tokenReserve)),
      symbol: string(abi.encodePacked('x', c.rateStrategy.tokenReserve)),
      implementation: aTokenImplAddress,
      params: bytes('')
    });

    ILendingPoolConfigurator.UpdateDebtTokenInput memory vdbtokenInput = ILendingPoolConfigurator.UpdateDebtTokenInput({
      asset: c.addr,
      incentivesController: incentivesController,
      name: string(abi.encodePacked('x', c.rateStrategy.tokenReserve)),
      symbol: string(abi.encodePacked('x', c.rateStrategy.tokenReserve)),
      implementation: aTokenImplAddress,
      params: bytes('')
    });
    lpc.updateAToken(atokenInput);
    lpc.updateStableDebtToken(sdbtokenInput);
    lpc.updateVariableDebtToken(vdbtokenInput);
  }
}
