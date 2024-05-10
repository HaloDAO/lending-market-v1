pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {CommonBase} from 'forge-std/Base.sol';
import 'forge-std/console2.sol';

import {IDeploymentLendingMarketConfig} from '../interfaces/IDeploymentLendingMarketConfig.sol';
import {IDeploymentXaveOraclesConfig} from '../interfaces/IDeploymentXaveOraclesConfig.sol';
import {IIncentivesControllerConfig} from '../interfaces/IIncentivesControllerConfig.sol';

contract DeploymentConfigHelper is CommonBase {
  function _readDeploymentLendingMarketConfig(
    string memory jsonFileName
  ) internal returns (IDeploymentLendingMarketConfig.Root memory) {
    bytes memory data = _readJsonFile(jsonFileName);
    IDeploymentLendingMarketConfig.Root memory root = abi.decode(data, (IDeploymentLendingMarketConfig.Root));

    return root;
  }

  function _readDeploymentLendingMarketTokenConfig(
    string memory jsonFileName
  ) internal returns (IDeploymentLendingMarketConfig.Token memory) {
    bytes memory data = _readJsonFile(jsonFileName);
    IDeploymentLendingMarketConfig.Token memory token = abi.decode(data, (IDeploymentLendingMarketConfig.Token));

    return token;
  }

  function _readDeploymentXaveOraclesConfig(
    string memory jsonFileName
  ) internal returns (IDeploymentXaveOraclesConfig.Root memory) {
    bytes memory data = _readJsonFile(jsonFileName);
    IDeploymentXaveOraclesConfig.Root memory root = abi.decode(data, (IDeploymentXaveOraclesConfig.Root));

    return root;
  }

  function _readDeploymentIncentivesConfig(
    string memory jsonFileName
  ) internal returns (IIncentivesControllerConfig.Root memory) {
    bytes memory data = _readJsonFile(jsonFileName);
    IIncentivesControllerConfig.Root memory root = abi.decode(data, (IIncentivesControllerConfig.Root));

    return root;
  }

  function _readJsonFile(string memory jsonFileName) internal returns (bytes memory) {
    string memory path = string(abi.encodePacked(vm.projectRoot(), '/deployments/', jsonFileName));
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);

    return data;
  }
}
