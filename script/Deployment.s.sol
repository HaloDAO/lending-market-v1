// deploy FXEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import 'forge-std/Script.sol';
import '../contracts/xave-oracles/FXEthPriceFeedOracle.sol';

contract Deployment is Script {
  address constant LP_XSGD = 0xE6D8FcD23eD4e417d7e9D1195eDf2cA634684e0E;
  address constant ETH_USD_ORACLE = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
  address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address constant XSGD_ASSIM = 0xC933a270B922acBd72ef997614Ec46911747b799;
  address constant USDC_ASSIM = 0xfbdc1B9E50F8607E6649d92542B8c48B2fc49a1a;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    vm.startBroadcast(deployerPrivateKey);

    FXEthPriceFeedOracle lpOracle = new FXEthPriceFeedOracle(
      LP_XSGD,
      ETH_USD_ORACLE,
      'LPXSGD-USDC/ETH',
      BALANCER_VAULT,
      XSGD_ASSIM,
      USDC_ASSIM
    );

    vm.stopBroadcast();
  }
}
