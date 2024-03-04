pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDeploymentXaveOraclesConfig {
  struct Root {
    BaseOracle[] baseOracles;
    LPOracle[] lpOracles;
  }

  struct LPOracle {
    string description;
    address ethUsdAggregator;
    address fxPool;
  }

  struct BaseOracle {
    address basePriceFeed;
    uint8 decimals;
    string description;
    address quotePriceFeed;
  }
}
