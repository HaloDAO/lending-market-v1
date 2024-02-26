pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDeploymentConfig {
  struct Root {
    DeploymentParams deploymentParams;
    ProtocolGlobalParams protocolGlobalParams;
    Token[] tokens;
  }
  struct DeploymentParams {
    address poolAdmin;
    address poolEmergencyAdmin;
  }

  struct ProtocolGlobalParams {
    address ethUsdAggregator;
    string marketId;
    // for each chain, this address represents the native token aggregator
    // eg. for avax it would be the avax-usd aggregator since the native token is avax
    // eg. for arbitrum it would be the eth-usd aggregator since the native token is eth
    address nativeTokenUsdChainLinkAggregator;
    address treasury;
    address usdAddress;
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
