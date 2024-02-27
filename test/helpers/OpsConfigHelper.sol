pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {CommonBase} from 'forge-std/Base.sol';

interface IOpsTestData {
  struct Root {
    BlockchainValues blockchain;
    ChainlinkValues chainlink;
    FaucetValues faucets;
    FXPoolValues fxPool;
    LendingPoolValues lendingPool;
    ReserveConfigsValues reserveConfigs;
    ReservesValues reserves;
    TokenValues tokens;
  }

  struct BlockchainValues {
    address eoaWallet;
    uint256 forkBlock;
  }

  struct ChainlinkValues {
    address ethUsd;
    address usdcUsd;
  }

  struct FaucetValues {
    address usdcWhale;
    address xsgdWhale;
  }

  struct FXPoolValues {
    address usdcAssimilator;
    address vault;
    address xsgdAssimilator;
    address xsgdUsdcFxp;
  }

  struct LendingPoolValues {
    address admin;
    address collateralManager;
    address donor;
    address emergencyAdmin;
    address lendingAddressProvider;
    address lendingPoolConfiguratorContract;
    address lendingPoolProxy;
    address lendingRateOracle;
    address oracleOwner;
    address poolAddress;
    address poolConfigurator;
    address priceOracle;
    address treasury;
  }

  struct ReserveConfigsValues {
    ReserveConfig lpXsgdUsdc;
  }

  struct ReserveConfig {
    uint256 baseLtv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 reserveDecimals;
    uint256 reserveFactor;
  }

  struct ReservesValues {
    address lpXsgdUsdc;
    address usdc;
    address xsgd;
  }

  struct TokenValues {
    address usdc;
    address xsgd;
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
