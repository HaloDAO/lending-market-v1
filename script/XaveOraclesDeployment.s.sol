// deploy FXLPEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import 'forge-std/console2.sol';

import {FXLPEthPriceFeedOracle} from '../contracts/xave-oracles/FXLPEthPriceFeedOracle.sol';
import {IDeploymentXaveOraclesConfig} from './interfaces/IDeploymentXaveOraclesConfig.sol';
import {DeploymentConfigHelper} from './helpers/DeploymentConfigHelper.sol';

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

    FXLPEthPriceFeedOracle o = new FXLPEthPriceFeedOracle(
      c.fxPool, // FXPool address
      c.ethUsdAggregator, // eg. ETH / USD
      c.description // eg 'LP-XSGD-USDC Oracle
    );

    vm.stopBroadcast();

    console2.log('~~~~~~~~~ POST DEPLOYMENT INFO ~~~~~~~~~');
  }
}
