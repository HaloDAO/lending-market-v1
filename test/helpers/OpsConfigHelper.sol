pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {CommonBase} from 'forge-std/Base.sol';

interface IOpsTestData {
  struct Root {
    LendingPoolValues lendingPool;
  }

  struct LendingPoolValues {
    address admin;
  }
}

contract OpsConfigHelper is CommonBase {
  function _readTestData(string memory jsonFileName) internal returns (IOpsTestData.Root memory) {
    string memory path = string(abi.encodePacked(vm.projectRoot(), '/test/data/', jsonFileName));
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);
    IOpsTestData.Root memory root = abi.decode(data, (IOpsTestData.Root));
    return root;
  }
}
