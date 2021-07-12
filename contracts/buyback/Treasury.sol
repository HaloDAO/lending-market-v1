// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { ILendingPool } from '../../interfaces/ILendingPool.sol';
import { IUniswapV2Router02 } from './interfaces/IUniswapV2Router02.sol';
import { SafeMath } from '@openzeppelin/contracts/math/SafeMath.sol';

contract Treasury {

    using SafeMath for uint256;

    address public lendingPool;
    address public router;
    address public rnbw;
    address public WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(address _lendingPool, address _router, address _rnbw) {
        lendingPool = _lendingPool;
        router = _router;
        rnbw = _rnbw;
    }

    function buybackRnbw(address[] calldata _underlyings) public returns (uint256) {

        uint256 totalRnbwBoughtBack = 0;
        uint256 rnbwBought;

        for (uint256 i = 0; i < _underlyings.length; i++) {
            uint underlyingAmount = ILendingPool(lendingPool).withdraw(_underlyings[i], type(uint256).max, address(this));

            //approve uniswap to swap
            IERC20(_underlyings[i]).approve(router, underlyingAmount);

            //create swap path
            address[] memory path = new address[](3);
            path[0] = _underlyings[i];
            path[1] = WETH9;
            path[2] = rnbw;

            rnbwBought = IUniswapV2Router02(router)
                        .swapExactTokensForTokens(underlyingAmount, 0, path, address(this), block.timestamp+60)[0];

            totalRnbwBoughtBack = totalRnbwBoughtBack.add(rnbwBought);
        }
        return totalRnbwBoughtBack;
    }


}
