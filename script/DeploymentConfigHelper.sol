pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import {CommonBase} from 'forge-std/Base.sol';
import 'forge-std/console2.sol';

interface IDeploymentConfig {
  struct Root {
    DeploymentParams deploymentParams;
    string marketId;
    ProtocolGlobalParams protocolGlobalParams;
    Token[] tokens;
  }
  struct DeploymentParams {
    address poolAdmin;
    address poolEmergencyAdmin;
  }

  struct ProtocolGlobalParams {
    address treasury;
    address usdAddress;
    address usdAggregator;
    address wethAddress;
  }

  struct Token {
    address addr;
    uint256 borrowRate;
    ChainlinkAggregator chainlinkAggregator;
    RateStrategy rateStrategy;
    ReserveConfig reserveConfig;
  }

  struct ChainlinkAggregator {
    address aggregator;
    string tokenReserve;
  }

  struct RateStrategy {
    uint256 baseVariableBorrowRate;
    string name;
    uint256 optimalUtilizationRate;
    uint256 stableRateSlope1;
    uint256 stableRateSlope2;
    string tokenReserve;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
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
    string tokenReserve;
  }
}

contract DeploymentConfigHelper is CommonBase {
  function _readDeploymentConfig(string memory jsonFileName) internal returns (IDeploymentConfig.Root memory) {
    string memory path = string(abi.encodePacked(vm.projectRoot(), '/deployments/', jsonFileName));
    string memory json = vm.readFile(path);
    bytes memory data = vm.parseJson(json);
    IDeploymentConfig.Root memory root = abi.decode(data, (IDeploymentConfig.Root));

    console2.log('tokens[1].rateStrategy.tokenReserve', root.tokens[1].rateStrategy.tokenReserve);
    console2.log('tokens[1].reserveConfig.tokenReserve', root.tokens[1].reserveConfig.tokenReserve);

    return root;
  }
}
