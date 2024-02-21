// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/utils/SafeCast.sol';

interface IAggregatorV3 {
  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract FXEthBasePriceFeedOracle {
  using SafeCast for uint;

  string public priceFeed;

  address public immutable basePriceFeed;
  address public immutable quotePriceFeed;

  uint8 public immutable decimals;

  constructor(address _basePriceFeed, address _quotePriceFeed, string memory _priceFeed) public {
    basePriceFeed = _basePriceFeed;
    quotePriceFeed = _quotePriceFeed;
    priceFeed = _priceFeed;
    decimals = 18;
  }

  function latestAnswer() external view returns (int256) {
    int256 _decimals = (10 ** (uint256(decimals))).toInt256();
    (, int256 basePrice, , , ) = IAggregatorV3(basePriceFeed).latestRoundData();
    uint8 baseDecimals = IAggregatorV3(basePriceFeed).decimals();

    basePrice = _scaleprice(basePrice, baseDecimals, decimals);

    (, int256 quotePrice, , , ) = IAggregatorV3(quotePriceFeed).latestRoundData();
    uint8 quoteDecimals = IAggregatorV3(quotePriceFeed).decimals();
    quotePrice = _scaleprice(quotePrice, quoteDecimals, decimals);

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
