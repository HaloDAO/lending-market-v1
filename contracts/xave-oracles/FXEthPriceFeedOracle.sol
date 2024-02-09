// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './libraries/SafeCast.sol';

import './libraries/ABDKMath64x64.sol';

// @TODO Safe math or Solidity >= 0.8
interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function decimals() external view returns (uint8);
}

interface FXPool {
  function liquidity() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);

  function protocolPercentFee() external view returns (uint256);

  function viewDeposit(uint256) external view returns (uint256);

  function getPoolId() external view returns (bytes32);
}

contract FXEthPriceFeedOracle {
  using SafeCast for uint256;

  using ABDKMath64x64 for int128;
  using ABDKMath64x64 for int256;
  using ABDKMath64x64 for uint256;

  string public priceFeed;

  FXPool public baseContract;
  AggregatorV3Interface public quotePriceFeed;
  address public vault;
  uint8 public decimals;
  bytes32 public poolId;
  uint256 constant WEIGHT = 5e17;
  address immutable baseAssimilator;
  address immutable quoteAssimilator;

  constructor(
    FXPool _baseContract,
    AggregatorV3Interface _quotePriceFeed,
    string memory _priceFeed,
    address _vault,
    address _baseAssimilator,
    address _quoteAssimilator
  ) public {
    baseContract = _baseContract;
    quotePriceFeed = _quotePriceFeed;
    priceFeed = _priceFeed;
    decimals = 18;
    vault = _vault;
    poolId = FXPool(baseContract).getPoolId();
    baseAssimilator = _baseAssimilator;
    quoteAssimilator = _quoteAssimilator;
  }

  function latestAnswer() external view returns (int256) {
    uint256 _decimals = uint256(10**uint256(decimals));
    uint256 liquidity = baseContract.liquidity();
    uint256 unclaimedFees = FXPool(baseContract).totalUnclaimedFeesInNumeraire();

    int128 balTokenQuote = IAssimilator(quoteAssimilator).viewNumeraireBalanceLPRatio(WEIGHT, WEIGHT, vault, poolId);

    int128 balTokenBase = IAssimilator(baseAssimilator).viewNumeraireBalanceLPRatio(WEIGHT, WEIGHT, vault, poolId);

    uint256 totalSupply = baseContract.totalSupply();

    int128 oGLiq = balTokenQuote + balTokenBase;

    // assimilator implementation
    uint256 totalSupplyWithUnclaimedFees = totalSupply +
      (((oGLiq.inv()).mulu(unclaimedFees) * totalSupply) / _decimals);

    uint256 hlp_usd = (liquidity * (_decimals)) / (totalSupplyWithUnclaimedFees);

    (, int256 quotePrice, , , ) = quotePriceFeed.latestRoundData();
    uint8 quoteDecimals = quotePriceFeed.decimals();
    quotePrice = _scaleprice(quotePrice, quoteDecimals, decimals);

    return ((hlp_usd.toInt256()) * ((uint256(10**18)).toInt256())) / (quotePrice);
  }

  function _scaleprice(
    int256 _price,
    uint8 _priceDecimals,
    uint8 _decimals
  ) internal pure returns (int256) {
    if (_priceDecimals < _decimals) {
      return _price * ((10**(uint256(_decimals - _priceDecimals))).toInt256());
    } else if (_priceDecimals > _decimals) {
      return _price / ((10**(uint256(_priceDecimals - _decimals))).toInt256());
    }
    return _price;
  }
}

interface IAssimilator {
  function viewNumeraireBalanceLPRatio(
    uint256,
    uint256,
    address,
    bytes32
  ) external view returns (int128);
}
