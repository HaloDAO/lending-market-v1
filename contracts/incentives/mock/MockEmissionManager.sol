// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IRnbwDistributionManager} from '../interfaces/IRnbwDistributionManager.sol';
import {DistributionTypes} from '../lib/DistributionTypes.sol';
import 'hardhat/console.sol';

contract MockEmissionManager is Ownable {
  address public incentivesController;

  function configure(DistributionTypes.AssetConfigInput[] calldata assetsConfigInput)
    external
    onlyOwner
  {
    IRnbwDistributionManager(incentivesController).configureAssets(assetsConfigInput);
  }

  function setIncentivesController(address _incentivesController) external onlyOwner {
    incentivesController = _incentivesController;
  }
}
