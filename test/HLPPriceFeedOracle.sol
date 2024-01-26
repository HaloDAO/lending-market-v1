// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import './SafeCast.sol';

interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function decimals() external view returns (uint8);
}

interface hlpContract {
  function liquidity() external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

contract hlpPriceFeedOracle {
  using SafeCast for uint;

  string public priceFeed;

  hlpContract public baseContract;
  AggregatorV3Interface public quotePriceFeed;

  uint8 public decimals;

  constructor(hlpContract _baseContract, AggregatorV3Interface _quotePriceFeed, string memory _priceFeed) public {
    baseContract = _baseContract;
    quotePriceFeed = _quotePriceFeed;
    priceFeed = _priceFeed;
    decimals = 18;
  }

  function latestAnswer() external view returns (int256) {
    uint256 _decimals = uint256(10 ** uint256(decimals));
    uint256 liquidity = baseContract.liquidity();
    uint256 totalSupply = baseContract.totalSupply();
    uint256 hlp_usd = (totalSupply * (_decimals)) / (liquidity);

    (, int256 quotePrice, , , ) = quotePriceFeed.latestRoundData();
    uint8 quoteDecimals = quotePriceFeed.decimals();
    quotePrice = _scaleprice(quotePrice, quoteDecimals, decimals);
    return ((hlp_usd.toInt256()) * ((uint256(10 ** 18)).toInt256())) / (quotePrice);
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
