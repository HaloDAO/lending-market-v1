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
import {IUniswapV2Pair} from './interfaces/IUniswapV2Pair.sol';

contract Treasury is Ownable {
  event RNBWBoughtAndSentToVesting(uint256 amountBought, address caller);

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  ICurveFactory public immutable curveFactory;

  address public immutable rainbowPool;
  address public immutable lendingPool;
  address public immutable rnbw;
  address public immutable usdc;
  address public immutable usdcRnbwPairAddress;

  constructor(
    address _lendingPool,
    address _rnbw,
    address _rainbowPool,
    address _curveFactory,
    address _usdc,
    address _usdcRnbwPairAddress
  ) public {
    lendingPool = _lendingPool;
    rnbw = _rnbw;
    rainbowPool = _rainbowPool;
    curveFactory = ICurveFactory(_curveFactory);
    usdc = _usdc;
    usdcRnbwPairAddress = _usdcRnbwPairAddress;
  }

  /**
   * @dev convert all fees collected to RNBW
   * @param _underlyings all hTokens for conversion
   * @param minRNBWAmount minimum RNBW amount expected, protection against price manipulation attacks
   **/

  function buybackRnbw(
    address[] calldata _underlyings,
    uint256 minRNBWAmount,
    uint256 deadline
  ) external onlyOwner returns (uint256) {
    // 1 - Withdraw and Convert to USDC
    for (uint256 i = 0; i < _underlyings.length; i++) {
      uint256 underlyingAmount = ILendingPool(lendingPool).withdraw(_underlyings[i], type(uint256).max, address(this));
      _convertToUsdc(_underlyings[i], underlyingAmount, deadline);
    }

    // 2 - Convert USDC to RNBW and send to vesting contract
    uint256 rnbwAmount = _swap(IERC20(usdc).balanceOf(address(this)), rainbowPool);

    require(rnbwAmount >= minRNBWAmount, 'Treasury: rnbwAmount is less than minRNBWAmount');

    emit RNBWBoughtAndSentToVesting(rnbwAmount, msg.sender);
  }

  /**
   * @dev helper function to convert all underlying assets into usdc before swapping to RNBW
   **/
  function _convertToUsdc(
    address _underlying,
    uint256 _underlyingAmount,
    uint256 deadline
  ) internal returns (uint256) {
    // 1 - Get curve
    ICurve curve = ICurve(curveFactory.getCurve(_underlying, usdc));
    IERC20(_underlying).approve(address(curve), _underlyingAmount);

    // 2 - Swap to USDC
    uint256 targetAmount = curve.originSwap(_underlying, usdc, _underlyingAmount, 0, deadline);
    return targetAmount;
  }

  /**
   * @dev Swaps usdc to rnbw from the USDC-RNBW Pool. fromToken will always be usdc and toToken will always be rainbow
   we simplified this to make it more gas efficient
   **/

  function _swap(uint256 amountIn, address to) internal returns (uint256 amountOut) {
    IUniswapV2Pair pair = IUniswapV2Pair(usdcRnbwPairAddress);

    (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
    uint256 amountInWithFee = amountIn.mul(997);

    amountOut = amountInWithFee.mul(reserve1).div(reserve0.mul(1000).add(amountInWithFee));
    IERC20(usdc).safeTransfer(address(pair), amountIn);
    pair.swap(0, amountOut, to, new bytes(0));
  }
}
