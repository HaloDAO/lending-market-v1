// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {ICurve} from '../interfaces/ICurve.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

contract CurveMock is ICurve {
  using SafeMath for uint256;

  uint256 public price;

  address public immutable tokenAddress;

  address public immutable USDC;

  uint256 private precision = 1e18;

  constructor(
    address _usdcAddress,
    address _tokenAddress,
    uint256 _price
  ) public {
    USDC = _usdcAddress;
    tokenAddress = _tokenAddress;
    price = _price;
  }

  /// @notice swap a dynamic origin amount for a fixed target amount
  /// @param _origin the address of the origin
  /// @param _target the address of the target
  /// @param _originAmount the origin amount
  /// @param _minTargetAmount the minimum target amount
  /// @param _deadline deadline in block number after which the trade will not execute
  /// @return targetAmount_ the amount of target that has been swapped for the origin amount
  function originSwap(
    address _origin,
    address _target,
    uint256 _originAmount,
    uint256 _minTargetAmount,
    uint256 _deadline
  ) external override returns (uint256 targetAmount_) {
    IERC20(_origin).transferFrom(msg.sender, address(this), _originAmount);
    targetAmount_ = _originAmount.mul(price).div(precision);
    IERC20(USDC).transfer(msg.sender, targetAmount_);
  }
}
