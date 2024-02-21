// deploy FXEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import 'forge-std/console2.sol';

import {FXEthPriceFeedOracle} from '../contracts/xave-oracles/FXEthPriceFeedOracle.sol';
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

  address constant LP_TOKEN = 0x0099111Ed107BDF0B05162356aEe433514AaC440; // VCHF/USDC LP
  address constant ETH_USD_ORACLE = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
  address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address constant VCHF_ASSIM = 0xC2750ad1cbD8523BE6e51F7d8FC6394dD7194D2d;
  address constant USDC_ASSIM = 0x21720736Ada52d8887aFAC20B05f02005fD6f272;
  // @TODO confirm correct
  address constant XAVE_TREASURY = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;
  // @TODO WETH.e address, there's also a WETH address
  address constant WETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

  function run() external {
    IDeploymentConfig.Root memory c = _readDeploymentConfig(string(abi.encodePacked('deployments_config.json')));

    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    address deployerAddress = vm.addr(deployerPrivateKey);

    vm.startBroadcast(deployerPrivateKey);

    // @TODO call all the setters on the LendingPoolAddressesProvider
    // see https://polygonscan.com/address/0x68aeB9C8775Cfc9b99753A1323D532556675c555#readContract
    LendingPoolAddressesProvider addressProvider = new LendingPoolAddressesProvider('Xave AVAX Market');
    // @TODO fix this, should be the wallet deploying the contracts or
    // some other wallet?
    // @TODO after deployment is done, the owner should be c.deploymentParams.poolAdmin and poolEmergecyAdmin
    addressProvider.setPoolAdmin(deployerAddress);
    addressProvider.setEmergencyAdmin(deployerAddress);

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
    console2.log('LendingPoolConfigurator', address(configurator));
    console2.log('LendingPoolConfiguratorProxy', configuratorProxy);

    // @TODO is this needed? how is it used?
    // stableAndVariableTokensHelper = await deployStableAndVariableTokensHelper(
    // [lendingPoolProxy.address, addressesProvider.address],
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

    _deployOracles(stableVarHelper, c);
    _deployDataProvider(addressProvider);
    _initReservesByHelper(addressProvider, c);
    _configureReservesByHelper(addressProvider, c, aTokensHelper, deployerAddress);

    vm.stopBroadcast();
  }

  // deploy Aave Oracle with assets, sources, fallbackOracle, baseCurrency, baseCurrencyUnit
  function _deployOracles(
    StableAndVariableTokensHelper _stableVarHelper,
    IDeploymentConfig.Root memory _c
  ) private returns (AaveOracle) {
    // @TODO this should be in a separate deployment file
    FXEthPriceFeedOracle lpOracle = new FXEthPriceFeedOracle(
      LP_TOKEN,
      ETH_USD_ORACLE,
      'LPVCHF-USDC/ETH',
      BALANCER_VAULT,
      VCHF_ASSIM,
      USDC_ASSIM
    );

    uint256 len = _c.borrowRates.length;
    address[] memory reserveAssets = new address[](len);
    uint256[] memory rates = new uint256[](len);
    address[] memory aggregators = new address[](len + 1);
    // tokensToWatch is reserveAssets + USD
    address[] memory tokensToWatch = new address[](len + 1);
    for (uint256 i = 0; i < len; i++) {
      reserveAssets[i] = _c.rateStrategy[i].tokenAddress;
      tokensToWatch[i] = _c.rateStrategy[i].tokenAddress;
      aggregators[i] = _c.chainlinkAggregators[i].aggregator;
      rates[i] = _c.borrowRates[i];
    }
    tokensToWatch[len] = _c.protocolGlobalParams.usdAddress;
    aggregators[len] = _c.protocolGlobalParams.usdAggregator;

    // AaveOracle calls _setAssetSources which also checks assets.length == sources.length
    AaveOracle oracle = new AaveOracle(
      tokensToWatch,
      aggregators,
      address(0), // fallbackOracle
      WETH, // baseCurrency
      1e18 // baseCurrencyUnit
    );

    LendingRateOracle lendingRateOracle = new LendingRateOracle();
    // transfer ownership to StableAndVariableTokensHelper
    lendingRateOracle.transferOwnership(address(_stableVarHelper));
    _stableVarHelper.setOracleBorrowRates(reserveAssets, rates, address(lendingRateOracle));
    // transfer back ownership
    // @TODO to where?
    _stableVarHelper.setOracleOwnership(address(lendingRateOracle), address(this));

    return oracle;
  }

  function _deployDataProvider(LendingPoolAddressesProvider _addressProvider) private {
    new AaveProtocolDataProvider(ILendingPoolAddressesProvider(_addressProvider));
  }

  function _deployDefaultReserveInterestStrategy(
    address _lendingPoolAddressProvider
  ) private returns (DefaultReserveInterestRateStrategy) {
    return
      new DefaultReserveInterestRateStrategy(
        ILendingPoolAddressesProvider(_lendingPoolAddressProvider),
        0.9 * 1e27, // optimal utilization rate
        0 * 1e27, // baseVariableBorrowRate
        0.04 * 1e27, // variableRateSlope1
        0.60 * 1e27, // variableRateSlope2
        0.02 * 1e27, // stableRateSlope1
        0.60 * 1e27 // stableRateSlope2
      );
  }

  function _deployAaveTokens(
    IDeploymentConfig.Root memory _c,
    address _ledingPoolProxy
  ) private returns (AToken[] memory aTokens, StableDebtToken[] memory sdTokens, VariableDebtToken[] memory vdTokens) {
    // @TODO do we need DelegationAwareAToken?
    // @see helpers/contracts-deployments.ts
    // cannot cache the length because of stack too deep error
    aTokens = new AToken[](_c.aTokens.length);
    sdTokens = new StableDebtToken[](_c.aTokens.length);
    vdTokens = new VariableDebtToken[](_c.aTokens.length);

    for (uint256 i = 0; i < _c.aTokens.length; i++) {
      AToken a = new AToken();
      a.initialize(
        ILendingPool(_ledingPoolProxy),
        _c.protocolGlobalParams.treasury,
        _c.aTokens[i].tokenAddress,
        // @TODO do we need an incentives controller?
        // can it be updated after?
        IAaveIncentivesController(address(0)),
        IERC20Detailed(_c.aTokens[i].tokenAddress).decimals(),
        string(abi.encodePacked('a', _c.aTokens[i].tokenName)),
        string(abi.encodePacked('a', _c.aTokens[i].tokenName)),
        bytes('')
      );
      aTokens[i] = a;

      StableDebtToken sdt = new StableDebtToken();
      sdt.initialize(
        ILendingPool(_ledingPoolProxy),
        _c.aTokens[i].tokenAddress,
        // @TODO do we need an incentives controller?
        // can it be updated after?
        IAaveIncentivesController(address(0)),
        IERC20Detailed(_c.aTokens[i].tokenAddress).decimals(),
        string(abi.encodePacked('sbt', _c.aTokens[i].tokenName)),
        string(abi.encodePacked('sbt', _c.aTokens[i].tokenName)),
        bytes('')
      );
      sdTokens[i] = sdt;

      VariableDebtToken vdt = new VariableDebtToken();
      vdt.initialize(
        ILendingPool(_ledingPoolProxy),
        _c.aTokens[i].tokenAddress,
        IAaveIncentivesController(address(0)),
        IERC20Detailed(_c.aTokens[i].tokenAddress).decimals(),
        string(abi.encodePacked('vdt', _c.aTokens[i].tokenName)),
        string(abi.encodePacked('vdt', _c.aTokens[i].tokenName)),
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

    uint256 l = _c.rateStrategy.length;

    for (uint256 i = 0; i < l; i++) {
      DefaultReserveInterestRateStrategy strategy = new DefaultReserveInterestRateStrategy(
        _addressProvider,
        _c.rateStrategy[i].optimalUtilizationRate,
        _c.rateStrategy[i].baseVariableBorrowRate,
        _c.rateStrategy[i].variableRateSlope1,
        _c.rateStrategy[i].variableRateSlope2,
        _c.rateStrategy[i].stableRateSlope1,
        _c.rateStrategy[i].stableRateSlope2
      );
      ILendingPoolConfigurator.InitReserveInput[] memory cfgInput = new ILendingPoolConfigurator.InitReserveInput[](1);
      cfgInput[0] = ILendingPoolConfigurator.InitReserveInput({
        aTokenImpl: address(aTokens[i]),
        stableDebtTokenImpl: address(sdTokens[i]),
        variableDebtTokenImpl: address(vdTokens[i]),
        underlyingAssetDecimals: IERC20Detailed(_c.rateStrategy[i].tokenAddress).decimals(),
        interestRateStrategyAddress: address(strategy),
        underlyingAsset: _c.rateStrategy[i].tokenAddress,
        treasury: _c.protocolGlobalParams.treasury,
        incentivesController: address(0),
        underlyingAssetName: _c.rateStrategy[i].tokenReserve,
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

    uint256 l = _c.reserveConfigs.length;
    ATokensAndRatesHelper.ConfigureReserveInput[]
      memory inputParams = new ATokensAndRatesHelper.ConfigureReserveInput[](l);
    for (uint256 i = 0; i < l; i++) {
      inputParams[i] = ATokensAndRatesHelper.ConfigureReserveInput({
        asset: _c.reserveConfigs[i].tokenAddress,
        baseLTV: _c.reserveConfigs[i].baseLTVAsCollateral,
        liquidationThreshold: _c.reserveConfigs[i].liquidationThreshold,
        liquidationBonus: _c.reserveConfigs[i].liquidationBonus,
        reserveFactor: _c.reserveConfigs[i].reserveFactor,
        stableBorrowingEnabled: _c.reserveConfigs[i].stableBorrowRateEnabled,
        borrowingEnabled: _c.reserveConfigs[i].borrowingEnabled
      });
    }

    _aTokensHelper.configureReserves(inputParams);

    _addressProvider.setPoolAdmin(_deployer);
  }
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}
