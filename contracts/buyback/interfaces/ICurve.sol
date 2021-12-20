// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ICurve {
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
  ) external returns (uint256 targetAmount_);
}
