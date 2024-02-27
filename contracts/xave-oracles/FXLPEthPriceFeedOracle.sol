// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './interfaces/IAggregatorV3Interface.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract FXLPEthPriceFeedOracle is IAggregatorV3Interface {
  using SafeMath for uint256;

  uint8 constant oracleDecimals = 18;
  uint256 constant WEIGHT = 5e17;
  string public priceFeed;
  address public immutable fxp;
  address public immutable quotePriceFeed;
  uint8 public immutable quoteDecimals;
  bytes32 public immutable poolId;

  constructor(
    address _fxp, // FXPool address
    address _quotePriceFeed, // eg. ETH / USD
    string memory _priceFeed
  ) public {
    fxp = _fxp;
    quotePriceFeed = _quotePriceFeed;
    quoteDecimals = IAggregatorV3Interface(_quotePriceFeed).decimals();
    priceFeed = _priceFeed;
    poolId = IFXPool(_fxp).getPoolId();
  }

  function aggregator() external view override returns (address) {
    return address(0);
  }

  function decimals() external view override returns (uint8) {
    return oracleDecimals;
  }

  function updateLatestAnswer() external returns (int256) {
    _price();
    emit AnswerUpdated(1, 1, block.timestamp);
  }

  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = 1;
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = 1;
    answer = _price();
  }

  function getAnswer(uint256 roundId) external view override returns (int256) {
    return _price();
  }

  function latestAnswer() external view override returns (int256) {
    return _price();
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = 1;
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = 1;
    answer = _price();
  }

  function proposedGetRoundData(uint80 roundId)
    external
    view
    override
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
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
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    id = 1;
    answer = _price();
    startedAt = block.timestamp;
    updatedAt = block.timestamp;
    answeredInRound = 1;
  }

  function _price() internal view returns (int256) {
    uint256 _decimals = uint256(10**uint256(oracleDecimals));
    (uint256 liquidity, ) = IFXPool(fxp).liquidity();
    uint256 unclaimedFees = IFXPool(fxp).totalUnclaimedFeesInNumeraire();

    uint256 hlp_usd = ((liquidity.sub(unclaimedFees)).mul(_decimals)).div(IFXPool(fxp).totalSupply());

    (, int256 quotePrice, uint256 startedAtBase, , ) = IAggregatorV3Interface(quotePriceFeed).latestRoundData();
    require(quotePrice > 0, 'P_PRICE_ZERO');
    require(startedAtBase != 0, 'P_ROUND_NOT_COMPLETE');
    require(startedAtBase + (3600 * 24) > block.timestamp, 'P_STALE_PRICE');

    quotePrice = _scaleprice(quotePrice, quoteDecimals, oracleDecimals);

    return int256((hlp_usd.mul(uint256(10**18))).div(uint256(quotePrice)));
  }

  function _scaleprice(
    int256 _price,
    uint8 _priceDecimals,
    uint8 _decimals
  ) internal pure returns (int256) {
    if (_priceDecimals < _decimals) {
      return int256(uint256(_price).mul(uint256((10**(uint256(_decimals - _priceDecimals))))));
    } else if (_priceDecimals > _decimals) {
      return int256(uint256(_price).mul(uint256((10**(uint256(_priceDecimals - _decimals))))));
    }
    return _price;
  }
}

interface IFXPool {
  function liquidity() external view returns (uint256, uint256[] memory);

  function totalSupply() external view returns (uint256);

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);

  function protocolPercentFee() external view returns (uint256);

  function viewDeposit(uint256) external view returns (uint256);

  function getPoolId() external view returns (bytes32);
}
