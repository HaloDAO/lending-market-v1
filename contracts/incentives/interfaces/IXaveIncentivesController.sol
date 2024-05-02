// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Simplified version of Aave's incentives controller
interface IXaveIncentivesController {
  function handleAction(address asset, uint256 userBalance, uint256 totalSupply) external;

  function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

  function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
}