// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {DistributionTypes} from './lib/DistributionTypes.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IAToken} from './interfaces/IAToken.sol';
import {IXaveIncentivesController} from './interfaces/IXaveIncentivesController.sol';
import {IStakedAave} from './interfaces/IStakedAave.sol';
import {VersionedInitializable} from './VersionedInitializable.sol';
import {XaveDistributionManager} from './XaveDistributionManager.sol';

/**
 * @title AaveIncentivesController
 * @notice Distributor contract for rewards to the Aave protocol
 * @author Aave
 **/
contract XaveIncentivesController is IXaveIncentivesController, VersionedInitializable, XaveDistributionManager {
  using SafeMath for uint256;
  uint256 public constant REVISION = 1;

  //IStakedAave public immutable PSM;

  IERC20 public immutable REWARD_TOKEN;
  //address public immutable REWARDS_VAULT;
  //uint256 public immutable EXTRA_PSM_REWARD;

  mapping(address => uint256) internal _usersUnclaimedRewards;

  event RewardsAccrued(address indexed user, uint256 amount);
  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  constructor(
    IERC20 rewardToken,
    address emissionManager,
    uint128 distributionDuration
  ) public XaveDistributionManager(emissionManager, distributionDuration) {
    REWARD_TOKEN = rewardToken;
  }

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param user The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(address user, uint256 userBalance, uint256 totalSupply) external override {
    uint256 accruedRewards = _updateUserAssetInternal(user, msg.sender, userBalance, totalSupply);

    if (accruedRewards != 0) {
      _usersUnclaimedRewards[user] = _usersUnclaimedRewards[user].add(accruedRewards);
      emit RewardsAccrued(user, accruedRewards);
    }
  }

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user) external view override returns (uint256) {
    uint256 unclaimedRewards = _usersUnclaimedRewards[user];

    DistributionTypes.UserStakeInput[] memory userState = new DistributionTypes.UserStakeInput[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      userState[i].underlyingAsset = assets[i];
      (userState[i].stakedByUser, userState[i].totalStaked) = IAToken(assets[i]).getScaledUserBalanceAndSupply(user);
    }
    unclaimedRewards = unclaimedRewards.add(_getUnclaimedRewards(user, userState));
    return unclaimedRewards;
  }

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(address[] calldata assets, uint256 amount, address to) external override returns (uint256) {
    if (amount == 0) {
      return 0;
    }
    address user = msg.sender;
    uint256 unclaimedRewards = _usersUnclaimedRewards[user];

    DistributionTypes.UserStakeInput[] memory userState = new DistributionTypes.UserStakeInput[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      userState[i].underlyingAsset = assets[i];
      (userState[i].stakedByUser, userState[i].totalStaked) = IAToken(assets[i]).getScaledUserBalanceAndSupply(user);
    }

    uint256 accruedRewards = _claimRewards(user, userState);
    if (accruedRewards != 0) {
      unclaimedRewards = unclaimedRewards.add(accruedRewards);
      emit RewardsAccrued(user, accruedRewards);
    }

    if (unclaimedRewards == 0) {
      return 0;
    }

    uint256 amountToClaim = amount > unclaimedRewards ? unclaimedRewards : amount;
    _usersUnclaimedRewards[user] = unclaimedRewards - amountToClaim; // Safe due to the previous line

    REWARD_TOKEN.transfer(to, amountToClaim);

    emit RewardsClaimed(msg.sender, to, amountToClaim);

    return amountToClaim;
  }

  /**
   * @dev returns the unclaimed rewards of the user
   * @param _user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address _user) external view returns (uint256) {
    return _usersUnclaimedRewards[_user];
  }

  /**
   * @dev returns the revision of the implementation contract
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }
}
