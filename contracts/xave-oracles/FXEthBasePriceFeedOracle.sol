// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import './interfaces/IAggregatorV3Interface.sol';

contract FXEthBasePriceFeedOracle is IAggregatorV3Interface {
  using SafeMath for uint256;

  string public description;
  address public immutable basePriceFeed;
  address public immutable quotePriceFeed;
  uint8 private immutable feedDecimals;

  constructor(address _basePriceFeed, address _quotePriceFeed, uint8 _decimals, string memory _description) public {
    basePriceFeed = _basePriceFeed;
    quotePriceFeed = _quotePriceFeed;
    description = _description;
    feedDecimals = _decimals;
  }

  function aggregator() external view override returns (address) {
    return address(0);
  }

  function decimals() external view override returns (uint8) {
    return feedDecimals;
  }

  function latestAnswer() external view override returns (int256) {
    return _price();
  }

  function getAnswer(uint256 roundId) external view override returns (int256) {
    return _price();
  }

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    roundId = 1;
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = 1;
    answer = _price();
  }

  function latestRoundData()
    external
    view
    override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    roundId = 1;
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = 1;
    answer = _price();
  }

  function proposedGetRoundData(
    uint80 roundId
  )
    external
    view
    override
    returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    id = 1;
    answer = _price();
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = 1;
  }

  function proposedLatestRoundData()
    external
    view
    override
    returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    id = 1;
    answer = _price();
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = 1;
  }

  function _price() internal view returns (int256) {
    int256 _decimals = int256(10 ** (uint256(feedDecimals)));

    (, int256 basePrice, uint256 startedAtBase, , ) = IAggregatorV3Interface(basePriceFeed).latestRoundData();

    require(basePrice > 0, 'P_PRICE_ZERO');
    require(startedAtBase != 0, 'P_ROUND_NOT_COMPLETE');
    require(startedAtBase + (3600 * 24) > block.timestamp, 'P_STALE_PRICE');

    uint8 baseDecimals = IAggregatorV3Interface(basePriceFeed).decimals();

    basePrice = _scaleprice(basePrice, baseDecimals, feedDecimals);

    (, int256 quotePrice, uint256 startedAtQuote, , ) = IAggregatorV3Interface(quotePriceFeed).latestRoundData();

    require(quotePrice > 0, 'Q_PRICE_ZERO');
    require(startedAtQuote != 0, 'Q_ROUND_NOT_COMPLETE');
    require(startedAtQuote + (3600 * 24) > block.timestamp, 'Q_STALE_PRICE');

    uint8 quoteDecimals = IAggregatorV3Interface(quotePriceFeed).decimals();
    // overrides quotePrice
    quotePrice = _scaleprice(quotePrice, quoteDecimals, feedDecimals);

    // already required base and quote price to be > 0
    return int256(uint256(basePrice).mul(uint256(_decimals)).div(uint256(quotePrice)));
  }

  function _scaleprice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns (int256) {
    if (_priceDecimals < _decimals) {
      return int256(uint256(_price).mul(uint256((10 ** (uint256(_decimals - _priceDecimals))))));
    } else if (_priceDecimals > _decimals) {
      return int256(uint256(_price).mul(uint256((10 ** (uint256(_priceDecimals - _decimals))))));
    }
    return _price;
  }
}
