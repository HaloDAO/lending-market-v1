// deploy FXEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import 'forge-std/Script.sol';
import {FXEthPriceFeedOracle} from '../contracts/xave-oracles/FXEthPriceFeedOracle.sol';
import {LendingPoolAddressesProviderRegistry} from '../contracts/protocol/configuration/LendingPoolAddressesProviderRegistry.sol';
import {LendingPoolAddressesProvider} from '../contracts/protocol/configuration/LendingPoolAddressesProvider.sol';
import {LendingPoolConfigurator} from '../contracts/protocol/lendingpool/LendingPoolConfigurator.sol';
import {LendingPool} from '../contracts/protocol/lendingpool/LendingPool.sol';
import {StableAndVariableTokensHelper} from '../contracts/deployments/StableAndVariableTokensHelper.sol';
import {ATokensAndRatesHelper} from '../contracts/deployments/ATokensAndRatesHelper.sol';

contract Deployment is Script {
  address constant LP_TOKEN = 0x0099111Ed107BDF0B05162356aEe433514AaC440; // VCHF/USDC LP
  address constant ETH_USD_ORACLE = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
  address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address constant VCHF_ASSIM = 0xC2750ad1cbD8523BE6e51F7d8FC6394dD7194D2d;
  address constant USDC_ASSIM = 0x21720736Ada52d8887aFAC20B05f02005fD6f272;

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

    // @TODO do config here
    StableAndVariableTokensHelper stableVarHelper = new StableAndVariableTokensHelper(
      lendingPoolProxy,
      address(provider)
    );
    ATokensAndRatesHelper aTokensHelper = new ATokensAndRatesHelper(
      lendingPoolProxy,
      address(provider),
      configuratorProxy
    );

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
}
