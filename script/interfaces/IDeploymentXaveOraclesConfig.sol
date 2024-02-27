pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDeploymentXaveOraclesConfig {
  struct Root {
    string description;
    address ethUsdAggregator;
    address fxPool;
  }
}
