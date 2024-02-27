pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {CommonBase} from 'forge-std/Base.sol';
import 'forge-std/console2.sol';

import {IDeploymentConfig} from '../interfaces/IDeploymentConfig.sol';

contract DeploymentConfigHelper is CommonBase {
  function _readDeploymentConfig(string memory jsonFileName) internal returns (IDeploymentConfig.Root memory) {
    string memory path = string(abi.encodePacked(vm.projectRoot(), '/deployments/', jsonFileName));
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);
    IDeploymentConfig.Root memory root = abi.decode(data, (IDeploymentConfig.Root));

    return root;
  }
}
