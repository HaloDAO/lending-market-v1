// deploy FXLPEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import 'forge-std/console2.sol';

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
import {LendingRateOracle} from '../contracts/mocks/oracle/LendingRateOracle.sol';
import {DeploymentConfigHelper, IDeploymentConfig} from './DeploymentConfigHelper.sol';
import {AaveProtocolDataProvider} from '../contracts/misc/AaveProtocolDataProvider.sol';
import {ILendingPoolConfigurator} from '../contracts/interfaces/ILendingPoolConfigurator.sol';

contract Deployment is Script, DeploymentConfigHelper {
  using stdJson for string;

  function run() external {
    IDeploymentConfig.Root memory c = _readDeploymentConfig(
      string(abi.encodePacked('deployments_config_sepolia.json'))
    );
    // uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    // address deployerAddress = vm.addr(deployerPrivateKey);
    // vm.startBroadcast(deployerPrivateKey);
    vm.startBroadcast();

    // @TODO call all the setters on the LendingPoolAddressesProvider
    // see https://polygonscan.com/address/0x68aeB9C8775Cfc9b99753A1323D532556675c555#readContract
    LendingPoolAddressesProvider addressProvider = new LendingPoolAddressesProvider('Xave AVAX Market');
    // hacky: get the actual sender wallet address from the ownable contract
    address deployerAddress = addressProvider.owner();
    // set the pool admin as the wallet deploying the contracts
    // later on we will transfer ownership to final desired owner
    addressProvider.setPoolAdmin(deployerAddress);

    LendingPoolAddressesProviderRegistry registry = new LendingPoolAddressesProviderRegistry();
    registry.registerAddressesProvider(address(addressProvider), 1);

    // deploy the LendingPool
    LendingPool lendingPool = new LendingPool();
    addressProvider.setLendingPoolImpl(address(lendingPool));
    address lendingPoolProxy = addressProvider.getLendingPool();
    // deploy the LendingPoolConfigurator
    LendingPoolConfigurator configurator = new LendingPoolConfigurator();
    addressProvider.setLendingPoolConfiguratorImpl(address(configurator));
    address configuratorProxy = addressProvider.getLendingPoolConfigurator();

    StableAndVariableTokensHelper stableVarHelper = new StableAndVariableTokensHelper(
      payable(lendingPoolProxy),
      address(addressProvider)
    );
    // const aTokensAndRatesHelper = await deployATokensAndRatesHelper
    ATokensAndRatesHelper aTokensHelper = new ATokensAndRatesHelper(
      payable(lendingPoolProxy),
      address(addressProvider),
      configuratorProxy
    );

    // await deployATokenImplementations(ConfigNames.Halo, poolConfig.ReservesConfig, verify);
    console2.log('deploying oracles');
    _deployOracles(addressProvider, stableVarHelper, c);
    console2.log('deploying data provider');
    _deployDataProvider(addressProvider);
    console2.log('init reserves by helper');
    _initReservesByHelper(addressProvider, c);
    _configureReservesByHelper(addressProvider, c, aTokensHelper, deployerAddress);

    // set final ownership
    registry.transferOwnership(c.deploymentParams.poolAdmin);
    addressProvider.setPoolAdmin(c.deploymentParams.poolAdmin);
    addressProvider.setEmergencyAdmin(c.deploymentParams.poolEmergencyAdmin);
    addressProvider.transferOwnership(c.deploymentParams.poolAdmin);
    stableVarHelper.transferOwnership(c.deploymentParams.poolAdmin);
    aTokensHelper.transferOwnership(c.deploymentParams.poolAdmin);

    vm.stopBroadcast();

    console2.log('~~~~~~~~~ POST DEPLOYMENT INFO ~~~~~~~~~');
    console2.log('LendingPool\t', addressProvider.getLendingPool());
    console2.log('LendingPoolCollateralManager\t', addressProvider.getLendingPoolCollateralManager());
    console2.log('LendingPoolConfigurator\t', addressProvider.getLendingPoolConfigurator());
    console2.log('~~~~~~~~~~~~ OWNERSHIP INFO ~~~~~~~~~~~~');

    console2.log('addressProvider owner\t', addressProvider.owner());
    console2.log('pool admin\t\t', addressProvider.getPoolAdmin());
    console2.log('pool emergency admin\t', addressProvider.getEmergencyAdmin());
    console2.log('registry owner\t', registry.owner());
    console2.log('stableVarHelper owner\t', stableVarHelper.owner());
    console2.log('aTokensHelper owner\t', aTokensHelper.owner());
  }

  // deploy Aave Oracle with assets, sources, fallbackOracle, baseCurrency, baseCurrencyUnit
  function _deployOracles(
    LendingPoolAddressesProvider _addressProvider,
    StableAndVariableTokensHelper _stableVarHelper,
    IDeploymentConfig.Root memory _c
  ) private {
    uint256 len = _c.tokens.length;
    address[] memory reserveAssets = new address[](len);
    uint256[] memory rates = new uint256[](len);
    address[] memory aggregators = new address[](len + 1);
    // tokensToWatch is reserveAssets + USD
    address[] memory tokensToWatch = new address[](len + 1);
    for (uint256 i = 0; i < len; i++) {
      reserveAssets[i] = _c.tokens[i].addr;
      tokensToWatch[i] = _c.tokens[i].addr;
      aggregators[i] = _c.tokens[i].chainlinkAggregator.aggregator;
      rates[i] = _c.tokens[i].borrowRate;
    }
    console2.log('treasury', _c.protocolGlobalParams.treasury);
    console2.log('USD', _c.protocolGlobalParams.usdAddress);
    console2.log('USD Aggregator', _c.protocolGlobalParams.usdAggregator);
    tokensToWatch[len] = _c.protocolGlobalParams.usdAddress;
    aggregators[len] = _c.protocolGlobalParams.usdAggregator;

    // AaveOracle calls _setAssetSources which also checks assets.length == sources.length
    AaveOracle oracle = new AaveOracle(
      tokensToWatch,
      aggregators,
      address(0), // fallbackOracle
      _c.protocolGlobalParams.wethAddress, // baseCurrency
      1e18 // baseCurrencyUnit
    );

    LendingRateOracle lendingRateOracle = new LendingRateOracle();

    _addressProvider.setPriceOracle(address(oracle));
    _addressProvider.setLendingRateOracle(address(lendingRateOracle));

    // transfer ownership to StableAndVariableTokensHelper
    lendingRateOracle.transferOwnership(address(_stableVarHelper));
    _stableVarHelper.setOracleBorrowRates(reserveAssets, rates, address(lendingRateOracle));
    // transfer back ownership
    _stableVarHelper.setOracleOwnership(address(lendingRateOracle), _c.deploymentParams.poolAdmin);
  }

  function _deployDataProvider(LendingPoolAddressesProvider _addressProvider) private {
    new AaveProtocolDataProvider(ILendingPoolAddressesProvider(_addressProvider));
  }

  function _deployAaveTokens(
    IDeploymentConfig.Root memory _c,
    address _ledingPoolProxy
  ) private returns (AToken[] memory aTokens, StableDebtToken[] memory sdTokens, VariableDebtToken[] memory vdTokens) {
    // @see helpers/contracts-deployments.ts
    // cannot cache the length because of stack too deep error
    aTokens = new AToken[](_c.tokens.length);
    sdTokens = new StableDebtToken[](_c.tokens.length);
    vdTokens = new VariableDebtToken[](_c.tokens.length);

    for (uint256 i = 0; i < _c.tokens.length; i++) {
      AToken a = new AToken();
      a.initialize(
        ILendingPool(_ledingPoolProxy),
        _c.protocolGlobalParams.treasury,
        _c.tokens[i].addr,
        // @TODO do we need an incentives controller?
        // can it be updated after?
        IAaveIncentivesController(address(0)),
        IERC20Detailed(_c.tokens[i].addr).decimals(),
        string(abi.encodePacked('a', _c.tokens[i].rateStrategy.tokenReserve)),
        string(abi.encodePacked('a', _c.tokens[i].rateStrategy.tokenReserve)),
        bytes('')
      );
      aTokens[i] = a;

      StableDebtToken sdt = new StableDebtToken();
      sdt.initialize(
        ILendingPool(_ledingPoolProxy),
        _c.tokens[i].addr,
        // @TODO do we need an incentives controller?
        // can it be updated after?
        IAaveIncentivesController(address(0)),
        IERC20Detailed(_c.tokens[i].addr).decimals(),
        string(abi.encodePacked('sbt', _c.tokens[i].rateStrategy.tokenReserve)),
        string(abi.encodePacked('sbt', _c.tokens[i].rateStrategy.tokenReserve)),
        bytes('')
      );
      sdTokens[i] = sdt;

      VariableDebtToken vdt = new VariableDebtToken();
      vdt.initialize(
        ILendingPool(_ledingPoolProxy),
        _c.tokens[i].addr,
        IAaveIncentivesController(address(0)),
        IERC20Detailed(_c.tokens[i].addr).decimals(),
        string(abi.encodePacked('vdt', _c.tokens[i].rateStrategy.tokenReserve)),
        string(abi.encodePacked('vdt', _c.tokens[i].rateStrategy.tokenReserve)),
        bytes('')
      );
      vdTokens[i] = vdt;
    }

    return (aTokens, sdTokens, vdTokens);
  }

  function _initReservesByHelper(
    LendingPoolAddressesProvider _addressProvider,
    IDeploymentConfig.Root memory _c
  ) private {
    (
      AToken[] memory aTokens,
      StableDebtToken[] memory sdTokens,
      VariableDebtToken[] memory vdTokens
    ) = _deployAaveTokens(_c, _addressProvider.getLendingPool());
    LendingPoolConfigurator cfg = LendingPoolConfigurator(_addressProvider.getLendingPoolConfigurator());

    uint256 l = _c.tokens.length;

    for (uint256 i = 0; i < l; i++) {
      DefaultReserveInterestRateStrategy strategy = new DefaultReserveInterestRateStrategy(
        _addressProvider,
        _c.tokens[i].rateStrategy.optimalUtilizationRate,
        _c.tokens[i].rateStrategy.baseVariableBorrowRate,
        _c.tokens[i].rateStrategy.variableRateSlope1,
        _c.tokens[i].rateStrategy.variableRateSlope2,
        _c.tokens[i].rateStrategy.stableRateSlope1,
        _c.tokens[i].rateStrategy.stableRateSlope2
      );
      ILendingPoolConfigurator.InitReserveInput[] memory cfgInput = new ILendingPoolConfigurator.InitReserveInput[](1);
      cfgInput[0] = ILendingPoolConfigurator.InitReserveInput({
        aTokenImpl: address(aTokens[i]),
        stableDebtTokenImpl: address(sdTokens[i]),
        variableDebtTokenImpl: address(vdTokens[i]),
        underlyingAssetDecimals: IERC20Detailed(_c.tokens[i].addr).decimals(),
        interestRateStrategyAddress: address(strategy),
        underlyingAsset: _c.tokens[i].addr,
        treasury: _c.protocolGlobalParams.treasury,
        incentivesController: address(0),
        underlyingAssetName: _c.tokens[i].rateStrategy.tokenReserve,
        aTokenName: aTokens[i].name(),
        aTokenSymbol: aTokens[i].symbol(),
        variableDebtTokenName: vdTokens[i].name(),
        variableDebtTokenSymbol: vdTokens[i].symbol(),
        stableDebtTokenName: sdTokens[i].name(),
        stableDebtTokenSymbol: sdTokens[i].symbol(),
        params: bytes('')
      });
      // hardhat deployment scripts set a chunk size of 1 here
      cfg.batchInitReserve(cfgInput);
    }
  }

  function _configureReservesByHelper(
    LendingPoolAddressesProvider _addressProvider,
    IDeploymentConfig.Root memory _c,
    ATokensAndRatesHelper _aTokensHelper,
    address _deployer
  ) private {
    _addressProvider.setPoolAdmin(address(_aTokensHelper));

    uint256 l = _c.tokens.length;
    ATokensAndRatesHelper.ConfigureReserveInput[]
      memory inputParams = new ATokensAndRatesHelper.ConfigureReserveInput[](l);
    for (uint256 i = 0; i < l; i++) {
      inputParams[i] = ATokensAndRatesHelper.ConfigureReserveInput({
        asset: _c.tokens[i].addr,
        baseLTV: _c.tokens[i].reserveConfig.baseLTVAsCollateral,
        liquidationThreshold: _c.tokens[i].reserveConfig.liquidationThreshold,
        liquidationBonus: _c.tokens[i].reserveConfig.liquidationBonus,
        reserveFactor: _c.tokens[i].reserveConfig.reserveFactor,
        stableBorrowingEnabled: _c.tokens[i].reserveConfig.stableBorrowRateEnabled,
        borrowingEnabled: _c.tokens[i].reserveConfig.borrowingEnabled
      });
    }

    _aTokensHelper.configureReserves(inputParams);
  }
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}
