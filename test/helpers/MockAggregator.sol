// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

contract MockAggregator {
  int256 private mockAnswer;
  uint8 public decimals;
  uint256 startedUpdated;

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

  constructor(int256 _initialAnswer, uint8 _decimals) public {
    mockAnswer = _initialAnswer;
    decimals = _decimals;
    emit AnswerUpdated(_initialAnswer, 0, now);
  }

  function setStartedUpdated(uint256 _startedUpdated) external {
    startedUpdated = _startedUpdated;
  }

  function latestAnswer() external view returns (int256) {
    return mockAnswer;
  }

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    roundId = 1;
    startedAt = startedUpdated != 0 ? startedUpdated : block.timestamp;
    updatedAt = startedUpdated != 0 ? startedUpdated : block.timestamp;
    answeredInRound = 1;
    answer = mockAnswer;
  }
}
