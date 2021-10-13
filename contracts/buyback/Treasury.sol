// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import {ICurve} from './interfaces/ICurve.sol';
import {ICurveFactory} from './interfaces/ICurveFactory.sol';
import {IUniswapV2ERC20} from './interfaces/IUniswapV2ERC20.sol';
import {IUniswapV2Pair} from './interfaces/IUniswapV2Pair.sol';
import {IUniswapV2Factory} from './interfaces/IUniswapV2Factory.sol';

contract Treasury is Ownable {
  event RNBWBoughtAndSentToVesting(uint256 amountBought, address caller);

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IUniswapV2Factory public immutable uniswapV2Factory;
  ICurveFactory public immutable curveFactory;

  address public immutable rainbowPool;
  address public immutable lendingPool;
  address public immutable rnbw;
  address public immutable usdc;

  constructor(
    address _lendingPool,
    address _rnbw,
    address _rainbowPool,
    address _curveFactory,
    address _uniswapV2Factory,
    address _usdc
  ) public {
    lendingPool = _lendingPool;
    rnbw = _rnbw;
    rainbowPool = _rainbowPool;
    curveFactory = ICurveFactory(_curveFactory);
    uniswapV2Factory = IUniswapV2Factory(_uniswapV2Factory);
    usdc = _usdc;
  }

  function buybackRnbw(address[] calldata _underlyings, uint256 minRNBWAmount)
    external
    onlyOwner
    returns (uint256)
  {
    // 1 - Withdraw and Convert to USDC
    for (uint256 i = 0; i < _underlyings.length; i++) {
      uint256 underlyingAmount = ILendingPool(lendingPool).withdraw(
        _underlyings[i],
        type(uint256).max,
        address(this)
      );
      convertToUsdc(_underlyings[i], underlyingAmount);
    }

    // 2 - Convert USDC to RNBW and send to vesting contract
    uint256 rnbwAmount = _swap(usdc, rnbw, IERC20(usdc).balanceOf(address(this)), rainbowPool);

    require(rnbwAmount >= minRNBWAmount, 'Treasury: rnbwAmount is less than minRNBWAmount');

    emit RNBWBoughtAndSentToVesting(rnbwAmount, msg.sender);
  }

  function convertToUsdc(address _underlying, uint256 _underlyingAmount)
    internal
    returns (uint256)
  {
    // 1 - Get curve
    ICurve curve = ICurve(curveFactory.getCurve(_underlying, usdc));
    IERC20(_underlying).approve(address(curve), _underlyingAmount);

    // 2 - Swap to USDC
    uint256 targetAmount = curve.originSwap(
      _underlying,
      usdc,
      _underlyingAmount,
      0,
      block.timestamp + 60
    );
    return targetAmount;
  }

  function _swap(
    address fromToken,
    address toToken,
    uint256 amountIn,
    address to
  ) internal returns (uint256 amountOut) {
    IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Factory.getPair(fromToken, toToken));

    require(address(pair) != address(0), 'Treasury: Cannot convert');
    (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
    uint256 amountInWithFee = amountIn.mul(997);

    if (fromToken == pair.token0()) {
      amountOut = amountInWithFee.mul(reserve1).div(reserve0.mul(1000).add(amountInWithFee));

      IERC20(fromToken).safeTransfer(address(pair), amountIn);
      pair.swap(0, amountOut, to, new bytes(0));
    } else {
      amountOut = amountInWithFee.mul(reserve0).div(reserve1.mul(1000).add(amountInWithFee));

      IERC20(fromToken).safeTransfer(address(pair), amountIn);
      pair.swap(amountOut, 0, to, new bytes(0));
    }
  }

  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'Treasury: Only EOA allowed');
    _;
  }
}
