// deploy FXEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import 'forge-std/Script.sol';
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

contract Deployment is Script {
  address constant LP_TOKEN = 0x0099111Ed107BDF0B05162356aEe433514AaC440; // VCHF/USDC LP
  address constant ETH_USD_ORACLE = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
  address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address constant VCHF_ASSIM = 0xC2750ad1cbD8523BE6e51F7d8FC6394dD7194D2d;
  address constant USDC_ASSIM = 0x21720736Ada52d8887aFAC20B05f02005fD6f272;
  // @TODO confirm correct
  address constant XAVE_TREASURY = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    vm.startBroadcast(deployerPrivateKey);

    // @TODO call all the setters on the LendingPoolAddressesProvider
    // see https://polygonscan.com/address/0x68aeB9C8775Cfc9b99753A1323D532556675c555#readContract
    LendingPoolAddressesProvider provider = new LendingPoolAddressesProvider('Xave AVAX Market');
    // @TODO set correct admin and emergency admin
    // provider.setPoolAdmin(ADMIN);
    // provider.setEmergencyAdmin(EMERGENCY_ADMIN);
    LendingPoolAddressesProviderRegistry registry = new LendingPoolAddressesProviderRegistry();
    registry.registerAddressesProvider(address(provider), 1);

    // deploy the LendingPool
    LendingPool lendingPool = new LendingPool();
    provider.setLendingPoolImpl(address(lendingPool));
    address payable lendingPoolProxy = payable(provider.getLendingPool());
    // deploy the LendingPoolConfigurator
    LendingPoolConfigurator configurator = new LendingPoolConfigurator();
    provider.setLendingPoolConfiguratorImpl(address(configurator));
    address configuratorProxy = provider.getLendingPoolConfigurator();

    // @TODO is this needed? how is it used?
    // stableAndVariableTokensHelper = await deployStableAndVariableTokensHelper(
    // [lendingPoolProxy.address, addressesProvider.address],
    StableAndVariableTokensHelper stableVarHelper = new StableAndVariableTokensHelper(
      lendingPoolProxy,
      address(provider)
    );
    // const aTokensAndRatesHelper = await deployATokensAndRatesHelper
    ATokensAndRatesHelper aTokensHelper = new ATokensAndRatesHelper(
      lendingPoolProxy,
      address(provider),
      configuratorProxy
    );

    // await deployATokenImplementations(ConfigNames.Halo, poolConfig.ReservesConfig, verify);
    // @TODO DelegationAwareAToken only on strategyUNI ?
    _deployAaveTokens(lendingPoolProxy, LP_TOKEN);

    // stuff
    FXEthPriceFeedOracle lpOracle = new FXEthPriceFeedOracle(
      LP_TOKEN,
      ETH_USD_ORACLE,
      'LPVCHF-USDC/ETH',
      BALANCER_VAULT,
      VCHF_ASSIM,
      USDC_ASSIM
    );

    vm.stopBroadcast();
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
    address _ledingPoolProxy,
    address _underlyingAsset
  ) private returns (AToken, StableDebtToken, VariableDebtToken) {
    // @TODO do we need DelegationAwareAToken?
    // @see helpers/contracts-deployments.ts
    AToken a = new AToken();
    // @TODO parameterize arguments
    a.initialize(
      ILendingPool(_ledingPoolProxy),
      XAVE_TREASURY,
      _underlyingAsset,
      // @TODO do we need an incentives controller?
      // can it be updated after?
      IAaveIncentivesController(address(0)),
      IERC20Detailed(_underlyingAsset).decimals(),
      'aVCHF-USDC',
      'aVCHF-USDC',
      bytes('')
    );

    StableDebtToken sdt = new StableDebtToken();
    sdt.initialize(
      ILendingPool(_ledingPoolProxy),
      _underlyingAsset,
      // @TODO do we need an incentives controller?
      // can it be updated after?
      IAaveIncentivesController(address(0)),
      IERC20Detailed(_underlyingAsset).decimals(),
      '__sbtVCHF-USDC',
      'sbtVCHF-USDC',
      bytes('')
    );
    VariableDebtToken vdt = new VariableDebtToken();

    vdt.initialize(
      ILendingPool(_ledingPoolProxy),
      _underlyingAsset,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(_underlyingAsset).decimals(),
      'vdtVCHF-USDC',
      'vdtVCHF-USDC',
      bytes('')
    );

    return (a, sdt, vdt);
  }
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}
