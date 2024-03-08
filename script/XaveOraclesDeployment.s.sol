// deploy FXLPEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import 'forge-std/console2.sol';

import {FXLPEthPriceFeedOracle} from '../contracts/xave-oracles/FXLPEthPriceFeedOracle.sol';
import {FXEthBasePriceFeedOracle} from '../contracts/xave-oracles/FXEthBasePriceFeedOracle.sol';
import {IDeploymentXaveOraclesConfig} from './interfaces/IDeploymentXaveOraclesConfig.sol';
import {DeploymentConfigHelper} from './helpers/DeploymentConfigHelper.sol';
import {IAggregatorV3Interface} from '../contracts/xave-oracles/interfaces/IAggregatorV3Interface.sol';

contract XaveOraclesDeployment is Script, DeploymentConfigHelper {
  using stdJson for string;

  function run(string memory network) external {
    IDeploymentXaveOraclesConfig.Root memory c = _readDeploymentXaveOraclesConfig(
      string(abi.encodePacked('xave_oracles_config.', network, '.json'))
    );

    // for local development uncomment the following lines
    // uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    // address deployerAddress = vm.addr(deployerPrivateKey);
    // vm.startBroadcast(deployerPrivateKey);
    vm.startBroadcast();

    console2.log('~~~~~~~~~ POST DEPLOYMENT INFO ~~~~~~~~~');
    console.log('LP Token Oracles');
    for (uint256 i = 0; i < c.lpOracles.length; i++) {
      FXLPEthPriceFeedOracle o = new FXLPEthPriceFeedOracle(
        c.lpOracles[i].fxPool, // FXPool address
        c.lpOracles[i].ethUsdAggregator, // eg. ETH / USD
        c.lpOracles[i].description // eg 'LP-XSGD-USDC Oracle
      );
      console2.log(c.lpOracles[i].description, ': ', address(o));
      console2.log(c.lpOracles[i].description, IAggregatorV3Interface(address(o)).latestAnswer());
    }
    console.log('Base Token Oracles');
    for (uint256 i = 0; i < c.baseOracles.length; i++) {
      FXEthBasePriceFeedOracle o = new FXEthBasePriceFeedOracle(
        c.baseOracles[i].basePriceFeed, // base price feed token / USD
        c.baseOracles[i].quotePriceFeed, // eg. ETH / USD
        c.baseOracles[i].decimals,
        c.baseOracles[i].description // eg 'LP-XSGD-USDC Oracle
      );

      console2.log(c.baseOracles[i].description, ': ', address(o));
      console2.log(c.baseOracles[i].description, IAggregatorV3Interface(address(o)).latestAnswer());
    }

    vm.stopBroadcast();
  }
}
