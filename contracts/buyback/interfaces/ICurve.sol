// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICurve {
  /* function setParams(
    uint256 _alpha,
    uint256 _beta,
    uint256 _feeAtHalt,
    uint256 _epsilon,
    uint256 _lambda
  ) external;

  /// @notice excludes an assimilator from the curve
  /// @param _derivative the address of the assimilator to exclude
  function excludeDerivative(address _derivative) external;

  /// @notice view the current parameters of the curve
  /// @return alpha_ the current alpha value
  ///  beta_ the current beta value
  ///  delta_ the current delta value
  ///  epsilon_ the current epsilon value
  ///  lambda_ the current lambda value
  ///  omega_ the current omega value
  function viewCurve()
    external
    view
    returns (
      uint256 alpha_,
      uint256 beta_,
      uint256 delta_,
      uint256 epsilon_,
      uint256 lambda_
    );

  function turnOffWhitelisting() external;

  function setEmergency(bool _emergency) external;

  function setFrozen(bool _toFreezeOrNotToFreeze) external;

  function transferOwnership(address _newOwner) external; */

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

  /* /// @notice view how much target amount a fixed origin amount will swap for
  /// @param _origin the address of the origin
  /// @param _target the address of the target
  /// @param _originAmount the origin amount
  /// @return targetAmount_ the target amount that would have been swapped for the origin amount
  function viewOriginSwap(
    address _origin,
    address _target,
    uint256 _originAmount
  ) external returns (uint256 targetAmount_);

  /// @notice swap a dynamic origin amount for a fixed target amount
  /// @param _origin the address of the origin
  /// @param _target the address of the target
  /// @param _maxOriginAmount the maximum origin amount
  /// @param _targetAmount the target amount
  /// @param _deadline deadline in block number after which the trade will not execute
  /// @return originAmount_ the amount of origin that has been swapped for the target
  function targetSwap(
    address _origin,
    address _target,
    uint256 _maxOriginAmount,
    uint256 _targetAmount,
    uint256 _deadline
  ) external returns (uint256 originAmount_);

  /// @notice view how much of the origin currency the target currency will take
  /// @param _origin the address of the origin
  /// @param _target the address of the target
  /// @param _targetAmount the target amount
  /// @return originAmount_ the amount of target that has been swapped for the origin
  function viewTargetSwap(
    address _origin,
    address _target,
    uint256 _targetAmount
  ) external returns (uint256 originAmount_);

  /// @notice deposit into the pool with no slippage from the numeraire assets the pool supports
  /// @param  index Index corresponding to the merkleProof
  /// @param  account Address coorresponding to the merkleProof
  /// @param  amount Amount coorresponding to the merkleProof, should always be 1
  /// @param  merkleProof Merkle proof
  /// @param  _deposit the full amount you want to deposit into the pool which will be divided up evenly amongst
  ///                  the numeraire assets of the pool
  /// @return (the amount of curves you receive in return for your deposit,
  ///          the amount deposited for each numeraire)
  function depositWithWhitelist(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 _deposit,
    uint256 _deadline
  ) external returns (uint256, uint256[] memory);

  /// @notice deposit into the pool with no slippage from the numeraire assets the pool supports
  /// @param  _deposit the full amount you want to deposit into the pool which will be divided up evenly amongst
  ///                  the numeraire assets of the pool
  /// @return (the amount of curves you receive in return for your deposit,
  ///          the amount deposited for each numeraire)
  function deposit(uint256 _deposit, uint256 _deadline)
    external returns (uint256, uint256[] memory);

  /// @notice view deposits and curves minted a given deposit would return
  /// @param _deposit the full amount of stablecoins you want to deposit. Divided evenly according to the
  ///                 prevailing proportions of the numeraire assets of the pool
  /// @return (the amount of curves you receive in return for your deposit,
  ///          the amount deposited for each numeraire)
  function viewDeposit(uint256 _deposit) external returns (uint256, uint256[] memory);

  /// @notice  Emergency withdraw tokens in the event that the oracle somehow bugs out
  ///          and no one is able to withdraw due to the invariant check
  /// @param   _curvesToBurn the full amount you want to withdraw from the pool which will be withdrawn from evenly amongst the
  ///                        numeraire assets of the pool
  /// @return withdrawals_ the amonts of numeraire assets withdrawn from the pool
  function emergencyWithdraw(uint256 _curvesToBurn, uint256 _deadline)
    external returns (uint256[] memory withdrawals_);

  /// @notice  withdrawas amount of curve tokens from the the pool equally from the numeraire assets of the pool with no slippage
  /// @param   _curvesToBurn the full amount you want to withdraw from the pool which will be withdrawn from evenly amongst the
  ///                        numeraire assets of the pool
  /// @return withdrawals_ the amonts of numeraire assets withdrawn from the pool
  function withdraw(uint256 _curvesToBurn, uint256 _deadline)
    external returns (uint256[] memory withdrawals_);

  /// @notice  views the withdrawal information from the pool
  /// @param   _curvesToBurn the full amount you want to withdraw from the pool which will be withdrawn from evenly amongst the
  ///                        numeraire assets of the pool
  /// @return the amonnts of numeraire assets withdrawn from the pool
  function viewWithdraw(uint256 _curvesToBurn)
    external returns (uint256[] memory);

  function supportsInterface(bytes4 _interface)
    external
    pure
    returns (bool supports_);

  /// @notice transfers curve tokens
  /// @param _recipient the address of where to send the curve tokens
  /// @param _amount the amount of curve tokens to send
  /// @return success_ the success bool of the call
  function transfer(address _recipient, uint256 _amount)
    external returns (bool success_);

  /// @notice transfers curve tokens from one address to another address
  /// @param _sender the account from which the curve tokens will be sent
  /// @param _recipient the account to which the curve tokens will be sent
  /// @param _amount the amount of curve tokens to transfer
  /// @return success_ the success bool of the call
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) external returns (bool success_);

  /// @notice approves a user to spend curve tokens on their behalf
  /// @param _spender the account to allow to spend from msg.sender
  /// @param _amount the amount to specify the spender can spend
  /// @return success_ the success bool of this call
  function approve(address _spender, uint256 _amount)
    external returns (bool success_);

  /// @notice view the curve token balance of a given account
  /// @param _account the account to view the balance of
  /// @return balance_ the curve token ballance of the given account
  function balanceOf(address _account) external view returns (uint256 balance_);

  /// @notice views the total curve supply of the pool
  /// @return totalSupply_ the total supply of curve tokens
  function totalSupply() external view returns (uint256 totalSupply_);

  /// @notice views the total allowance one address has to spend from another address
  /// @param _owner the address of the owner
  /// @param _spender the address of the spender
  /// @return allowance_ the amount the owner has allotted the spender
  function allowance(address _owner, address _spender) external view returns (uint256 allowance_);

  /// @notice views the total amount of liquidity in the curve in numeraire value and format - 18 decimals
  /// @return total_ the total value in the curve
  /// @return individual_ the individual values in the curve
  function liquidity() external view returns (uint256 total_, uint256[] memory individual_);

  /// @notice view the assimilator address for a derivative
  /// @return assimilator_ the assimilator address
  function assimilator(address _derivative) external view returns (address assimilator_); */
}
