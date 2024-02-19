// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import './libraries/SafeCast.sol';

import './libraries/ABDKMath64x64.sol';
import './libraries/Math.sol';

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

contract FXEthPriceFeedOracle {
  using SafeCast for uint256;

  using ABDKMath64x64 for int128;
  using ABDKMath64x64 for int256;
  using ABDKMath64x64 for uint256;

  uint8 constant decimals = 18;
  uint256 constant WEIGHT = 5e17;
  string public priceFeed;
  address public immutable fxp;
  address public immutable quotePriceFeed;
  uint8 public immutable quoteDecimals;
  address public immutable vault;
  bytes32 public immutable poolId;
  address public immutable baseAssimilator;
  address public immutable quoteAssimilator;

  constructor(
    address _fxp, // FXPool address
    address _quotePriceFeed, // eg. ETH / USD
    string memory _priceFeed,
    address _vault, // Balance Vault
    address _baseAssimilator,
    address _quoteAssimilator
  ) public {
    fxp = _fxp;
    quotePriceFeed = _quotePriceFeed;
    quoteDecimals = IAggregatorV3Interface(_quotePriceFeed).decimals();
    priceFeed = _priceFeed;
    vault = _vault;
    poolId = IFXPool(_fxp).getPoolId();
    baseAssimilator = _baseAssimilator;
    quoteAssimilator = _quoteAssimilator;
  }

  function latestAnswer() external view returns (int256) {
    uint256 _decimals = uint256(10 ** uint256(decimals));
    (uint256 liquidity, ) = IFXPool(fxp).liquidity();
    uint256 unclaimedFees = IFXPool(fxp).totalUnclaimedFeesInNumeraire();

    uint256 hlp_usd = ((liquidity - unclaimedFees) * _decimals) / IFXPool(fxp).totalSupply();

    (, int256 quotePrice, , , ) = IAggregatorV3Interface(quotePriceFeed).latestRoundData();
    quotePrice = _scaleprice(quotePrice, quoteDecimals, decimals);

    return ((hlp_usd.toInt256()) * ((uint256(10 ** 18)).toInt256())) / (quotePrice);
  }

  // function latestAnswer() external view returns (int256) {
  //   uint256 _decimals = uint256(10 ** uint256(decimals));
  //   (uint256 liquidity, ) = IFXPool(fxp).liquidity();
  //   uint256 unclaimedFees = IFXPool(fxp).totalUnclaimedFeesInNumeraire();

  //   int128 balTokenQuote = IAssimilator(quoteAssimilator).viewNumeraireBalanceLPRatio(WEIGHT, WEIGHT, vault, poolId);

  //   int128 balTokenBase = IAssimilator(baseAssimilator).viewNumeraireBalanceLPRatio(WEIGHT, WEIGHT, vault, poolId);

  //   uint256 totalSupply = IFXPool(fxp).totalSupply();

  //   int128 oGLiq = balTokenQuote + balTokenBase;

  //   // assimilator implementation
  //   uint256 totalSupplyWithUnclaimedFees = totalSupply +
  //     (((oGLiq.inv()).mulu(unclaimedFees) * totalSupply) / _decimals);

  //   uint256 hlp_usd = (liquidity * (_decimals)) / (totalSupplyWithUnclaimedFees);

  //   (, int256 quotePrice, , , ) = IAggregatorV3Interface(quotePriceFeed).latestRoundData();
  //   quotePrice = _scaleprice(quotePrice, quoteDecimals, decimals);

  //   return ((hlp_usd.toInt256()) * ((uint256(10 ** 18)).toInt256())) / (quotePrice);
  // }

  function _scaleprice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns (int256) {
    if (_priceDecimals < _decimals) {
      return _price * ((10 ** (uint256(_decimals - _priceDecimals))).toInt256());
    } else if (_priceDecimals > _decimals) {
      return _price / ((10 ** (uint256(_priceDecimals - _decimals))).toInt256());
    }
    return _price;
  }
}

interface IAssimilator {
  function viewNumeraireBalanceLPRatio(uint256, uint256, address, bytes32) external view returns (int128);
}

interface IAggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function decimals() external view returns (uint8);
}

interface IFXPool {
  function liquidity() external view returns (uint256, uint256[] memory);

  function totalSupply() external view returns (uint256);

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);

  function protocolPercentFee() external view returns (uint256);

  function viewDeposit(uint256) external view returns (uint256);

  function getPoolId() external view returns (bytes32);
}
