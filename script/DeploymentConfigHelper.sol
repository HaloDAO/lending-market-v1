pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {CommonBase} from 'forge-std/Base.sol';

interface IDeploymentConfig {
  struct Root {
    ATokens[] aTokens;
    uint256[] borrowRates;
    // @TODO need to deploy in advance and update the JSON config file
    ChainlinkAggregator[] chainlinkAggregators;
    string marketId;
    ProtocolGlobalParams protocolGlobalParams;
    RateStrategy[] rateStrategy;
    ReserveConfig[] reserveConfigs;
  }

  struct ATokens {
    address tokenAddress;
    string tokenName;
  }

  struct ChainlinkAggregator {
    address aggregator;
    string tokenReserve;
  }

  struct ProtocolGlobalParams {
    address treasury;
    address usdAddress;
    address usdAggregator;
  }

  struct ReserveConfig {
    string aTokenImpl;
    uint256 baseLTVAsCollateral;
    bool borrowingEnabled;
    uint256 liquidationBonus;
    uint256 liquidationThreshold;
    uint256 reserveDecimals;
    uint256 reserveFactor;
    bool stableBorrowRateEnabled;
    address tokenAddress;
    string tokenReserve;
  }

  struct RateStrategy {
    uint256 baseVariableBorrowRate;
    uint256 optimalUtilizationRate;
    string name;
    uint256 stableRateSlope1;
    uint256 stableRateSlope2;
    address tokenAddress;
    string tokenReserve;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
  }
}

contract DeploymentConfigHelper is CommonBase {
  function _readDeploymentConfig(string memory jsonFileName) internal returns (IDeploymentConfig.Root memory) {
    string memory path = string(abi.encodePacked(vm.projectRoot(), '/deployments/', jsonFileName));
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);
    IDeploymentConfig.Root memory root = abi.decode(data, (IDeploymentConfig.Root));

    require(root.borrowRates.length == root.rateStrategy.length, 'borrowRates.length != rateStrategy.length');
    require(
      root.borrowRates.length == root.chainlinkAggregators.length,
      'borrowRates.length != chainlinkAggregators.length'
    );
    require(root.borrowRates.length == root.reserveConfigs.length, 'borrowRates.length != reserveConfigs.length');
    require(root.borrowRates.length == root.aTokens.length, 'borrowRates.length != aTokens.length');

    return root;
  }
}
