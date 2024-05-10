pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IIncentivesControllerConfig {
  struct Root {
    address emissionManager;
    uint128 distributionDuration;
    address rewardToken;
  }
}
