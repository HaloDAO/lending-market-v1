// deploy FXLPEthPriceFeedOracle.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Script.sol';
import 'forge-std/StdJson.sol';
import 'forge-std/console2.sol';

import {DeploymentConfigHelper} from './helpers/DeploymentConfigHelper.sol';
import {IIncentivesControllerConfig} from './interfaces/IIncentivesControllerConfig.sol';
import {XaveIncentivesController} from '../contracts/incentives/XaveIncentivesController.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract LendingPoolDeployIncentivesController is Script, DeploymentConfigHelper {
  using stdJson for string;

  function run(string memory network) external {
    vm.startBroadcast();
    console2.log('Broadcasting transactions..');
    _execute(network);
    vm.stopBroadcast();
  }

  function _execute(string memory network) private {
    IIncentivesControllerConfig.Root memory c = _readDeploymentIncentivesConfig(
      string(abi.encodePacked('incentives/incentives_config.', network, '.json'))
    );
    XaveIncentivesController incentivesController = new XaveIncentivesController(
      IERC20(c.rewardToken),
      c.emissionManager,
      c.distributionDuration
    );

    console2.log('incentive controller address: ', address(incentivesController));
  }
}
