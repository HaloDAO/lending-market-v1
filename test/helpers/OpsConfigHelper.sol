pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {CommonBase} from 'forge-std/Base.sol';

interface IOpsTestData {
  struct Root {
    LendingPoolValues lendingPool;
    ReservesValues reserves;
  }

  struct LendingPoolValues {
    address admin;
    address poolAddress;
    address poolConfigurator;
    address collateralManager;
    address emergencyAdmin;
    address priceOracle;
    address lendingRateOracle;
    address oracleOwner;
  }

  struct ReservesValues {
    address USDC;
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
