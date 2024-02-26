// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IAggregatorV3Interface {
  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

  function aggregator() external view returns (address);

  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestAnswer() external view returns (int256);

  function getAnswer(uint256 roundId) external view returns (int256);

  // IAggregatorPricingOnly
  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function proposedGetRoundData(
    uint80 roundId
  ) external view returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function proposedLatestRoundData()
    external
    view
    returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
