// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './libraries/SafeCast.sol';

import './libraries/ABDKMath64x64.sol';
import './libraries/Math.sol';
// @TODO remove
import 'forge-std/console2.sol';

// @TODO move all arithmetic operations to SafeMath
// @TODO add latestRoundData, make this contract compatible with Chainlink
// @TODO get weights at deployment time (in the constructor)
// @TODO quotePriceFeed.latestRoundData stale? discuss with the team
// @TODO rename baseContract -> fxpool ?
// @TODO we're only using inv() from ABDK - can we remove the dependency?
// @TODO write a test that compares the price of the LP token at different pool ratios:
//       - 50% : 50%
//       - 80% : 20% (halts)
//       - 20% : 80% (halts)
// @TODO add a test that compares the price of the LP token with different XSGD price movements
//       - +5%,  10%,  15%
//       - -5%, -10%, -15%
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
  function liquidity() external view returns (uint256, uint256[] memory);

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

  // @TODO change all vars to be address rather than contract / interface
  FXPool public immutable baseContract;
  AggregatorV3Interface public quotePriceFeed;
  address public vault;
  uint8 public constant decimals = 18;
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
    vault = _vault;
    poolId = FXPool(_baseContract).getPoolId();
    baseAssimilator = _baseAssimilator;
    quoteAssimilator = _quoteAssimilator;
  }

  // @TODO remove / rename
  function latestAnswer3() external view returns (int256) {
    // console2.log('SQRT(Math.bmul(13e18, 7e18))', Math.bsqrt(Math.bmul(13e18, 7e18), true));
    uint256 _decimals = uint256(10**uint256(decimals));
    (uint256 totalLiq, uint256[] memory indvLiq) = baseContract.liquidity();
    uint256 unclaimedFees = FXPool(baseContract).totalUnclaimedFeesInNumeraire();

    int128 balTokenQuote = IAssimilator(quoteAssimilator).viewNumeraireBalanceLPRatio(WEIGHT, WEIGHT, vault, poolId);

    int128 balTokenBase = IAssimilator(baseAssimilator).viewNumeraireBalanceLPRatio(WEIGHT, WEIGHT, vault, poolId);

    uint256 totalSupply = baseContract.totalSupply();

    int128 oGLiq = balTokenQuote + balTokenBase;

    // assimilator implementation
    uint256 totalSupplyWithUnclaimedFees = totalSupply +
      (((oGLiq.inv()).mulu(unclaimedFees) * totalSupply) / _decimals);

    (, int256 quotePrice, , , ) = quotePriceFeed.latestRoundData();
    // @TODO move `quotePriceFeed.decimals` to immutable var
    uint8 quoteDecimals = quotePriceFeed.decimals();
    quotePrice = _scaleprice(quotePrice, quoteDecimals, decimals);

    // SQRT(liq0 * liq1)
    uint256 square = Math.bsqrt(Math.bmul(indvLiq[0], indvLiq[1]), true);
    // 2e18 * sqrt(...) / totalSupply
    uint256 hlp_usd = Math.bdiv(Math.bmul(Math.TWO_BONES, square), totalSupplyWithUnclaimedFees);

    return ((hlp_usd.toInt256()) * ((uint256(10**18)).toInt256())) / (quotePrice);
  }

  // @TODO remove / rename
  function latestAnswer2() external view returns (int256) {
    uint256 _decimals = uint256(10**uint256(decimals));
    (uint256 liquidity, ) = baseContract.liquidity();
    uint256 unclaimedFees = FXPool(baseContract).totalUnclaimedFeesInNumeraire();

    uint256 hlp_usd = ((liquidity - unclaimedFees) * _decimals) / baseContract.totalSupply();

    (, int256 quotePrice, , , ) = quotePriceFeed.latestRoundData();
    // @TODO move `quotePriceFeed.decimals` to immutable var
    uint8 quoteDecimals = quotePriceFeed.decimals();
    quotePrice = _scaleprice(quotePrice, quoteDecimals, decimals);

    return ((hlp_usd.toInt256()) * ((uint256(10**18)).toInt256())) / (quotePrice);
  }

  function latestAnswer() external view returns (int256) {
    uint256 _decimals = uint256(10**uint256(decimals));
    (uint256 liquidity, ) = baseContract.liquidity();
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
