// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import { IERC20 } from '@openzeppelin/contracts/access/Ownable.sol';
import { IRnbwDistributionManager } from '../interfaces/IRnbwDistributionManager.sol';
import {DistributionTypes} from '../lib/DistributionTypes.sol';
contract MockEmissionManager is Ownable {

    address incentivesController;

    constructor(address _incentivesController) public {
        incentivesController = _incentivesController;
    }

    function setEmissionRate(DistributionTypes.AssetConfigInput[] calldata assetsConfigInput) onlyOwner public {
        IRnbwDistributionManager(incentivesController).configureAssets(assetsConfigInput);
    }



}
