pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {CommonBase} from 'forge-std/Base.sol';

interface IOpsTestData {
  struct Root {
    ChainlinkValues chainlink;
    FXPoolValues fxPool;
    LendingPoolValues lendingPool;
    ReservesValues reserves;
  }

  struct ChainlinkValues {
    address usdEth;
    address usdUsdc;
  }

  struct FXPoolValues {
    address vault;
    address xsgdUsdcFxp;
  }

  struct LendingPoolValues {
    address admin;
    address collateralManager;
    address emergencyAdmin;
    address lendingRateOracle;
    address oracleOwner;
    address poolAddress;
    address poolConfigurator;
    address priceOracle;
  }

  struct ReservesValues {
    address usdc;
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
