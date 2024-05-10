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

//
contract XaveOraclesAdditionalDeployment is Script, DeploymentConfigHelper {
  using stdJson for string;

  function run(string memory network, bool isLp, uint256 oracleIndex) external {
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

    if (isLp) {
      console.log('Deploying LP Token Oracle');
      FXLPEthPriceFeedOracle o = new FXLPEthPriceFeedOracle(
        c.lpOracles[oracleIndex].fxPool, // FXPool address
        c.lpOracles[oracleIndex].ethUsdAggregator, // eg. ETH / USD
        c.lpOracles[oracleIndex].description // eg 'LP-XSGD-USDC Oracle
      );

      console2.log(c.lpOracles[oracleIndex].description, ': ', address(o));
      console2.log(c.lpOracles[oracleIndex].description, IAggregatorV3Interface(address(o)).latestAnswer());
    } else {
      console.log('Deploying Base Token Oracle');
      FXEthBasePriceFeedOracle o = new FXEthBasePriceFeedOracle(
        c.baseOracles[oracleIndex].basePriceFeed, // base price feed token / USD
        c.baseOracles[oracleIndex].quotePriceFeed, // eg. ETH / USD
        c.baseOracles[oracleIndex].decimals,
        c.baseOracles[oracleIndex].description // eg 'LP-XSGD-USDC Oracle
      );

      console2.log(c.baseOracles[oracleIndex].description, ': ', address(o));
      console2.log(c.baseOracles[oracleIndex].description, IAggregatorV3Interface(address(o)).latestAnswer());
    }

    vm.stopBroadcast();
  }
}
