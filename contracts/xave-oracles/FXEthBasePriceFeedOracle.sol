// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/utils/SafeCast.sol';

interface IAggregatorV3 {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract FXEthBasePriceFeedOracle is IAggregatorV3 {
  using SafeCast for uint;

  string public description;

  address public immutable basePriceFeed;
  address public immutable quotePriceFeed;

  uint8 private immutable feedDecimals;

  constructor(address _basePriceFeed, address _quotePriceFeed, string memory _description) public {
    basePriceFeed = _basePriceFeed;
    quotePriceFeed = _quotePriceFeed;
    description = _description;
    feedDecimals = 18;
  }

  function decimals() external view override returns (uint8) {
    return feedDecimals;
  }

  function latestAnswer() external view override returns (int256) {
    return _price();
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

  function _price() internal view returns (int256) {
    int256 _decimals = (10 ** (uint256(feedDecimals))).toInt256();

    (, int256 basePrice, uint256 startedAtBase, , ) = IAggregatorV3(basePriceFeed).latestRoundData();

    require(basePrice > 0, 'P_PRICE_ZERO');
    require(startedAtBase != 0, 'P_ROUND_NOT_COMPLETE');
    require(startedAtBase + (3600 * 24) > block.timestamp, 'P_STALE_PRICE');

    uint8 baseDecimals = IAggregatorV3(basePriceFeed).decimals();

    basePrice = _scaleprice(basePrice, baseDecimals, feedDecimals);

    (, int256 quotePrice, uint256 startedAtQuote, , ) = IAggregatorV3(quotePriceFeed).latestRoundData();

    require(quotePrice > 0, 'Q_PRICE_ZERO');
    require(startedAtQuote != 0, 'Q_ROUND_NOT_COMPLETE');
    require(startedAtQuote + (3600 * 24) > block.timestamp, 'Q_STALE_PRICE');

    uint8 quoteDecimals = IAggregatorV3(quotePriceFeed).decimals();
    // overrides quotePrice
    quotePrice = _scaleprice(quotePrice, quoteDecimals, feedDecimals);

    return (basePrice * _decimals) / quotePrice;
  }

  function _scaleprice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns (int256) {
    if (_priceDecimals < _decimals) {
      return _price * ((10 ** (uint256(_decimals - _priceDecimals))).toInt256());
    } else if (_priceDecimals > _decimals) {
      return _price / ((10 ** (uint256(_priceDecimals - _decimals))).toInt256());
    }
    return _price;
  }
}
