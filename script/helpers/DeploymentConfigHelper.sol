pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {CommonBase} from 'forge-std/Base.sol';
import 'forge-std/console2.sol';

import {IDeploymentLendingMarketConfig} from '../interfaces/IDeploymentLendingMarketConfig.sol';
import {IDeploymentXaveOraclesConfig} from '../interfaces/IDeploymentXaveOraclesConfig.sol';

contract DeploymentConfigHelper is CommonBase {
  function _readDeploymentLendingMarketConfig(
    string memory jsonFileName
  ) internal returns (IDeploymentLendingMarketConfig.Root memory) {
    bytes memory data = _readJsonFile(jsonFileName);
    IDeploymentLendingMarketConfig.Root memory root = abi.decode(data, (IDeploymentLendingMarketConfig.Root));

    return root;
  }

  function _readDeploymentXaveOraclesConfig(
    string memory jsonFileName
  ) internal returns (IDeploymentXaveOraclesConfig.Root memory) {
    bytes memory data = _readJsonFile(jsonFileName);
    IDeploymentXaveOraclesConfig.Root memory root = abi.decode(data, (IDeploymentXaveOraclesConfig.Root));

    return root;
  }

  function _readJsonFile(string memory jsonFileName) internal returns (bytes memory) {
    string memory path = string(abi.encodePacked(vm.projectRoot(), '/deployments/', jsonFileName));
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);

    return data;
  }
}
