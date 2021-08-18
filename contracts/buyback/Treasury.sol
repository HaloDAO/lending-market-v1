// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {IUniswapV2Router02} from './interfaces/IUniswapV2Router02.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ICurve} from './interfaces/ICurve.sol';
import {ICurveFactory} from './interfaces/ICurveFactory.sol';
import 'hardhat/console.sol';

contract Treasury is Ownable {
  event RnbwBought(uint256 amount, address caller);
  event RnbwSentToVesting(uint256 amount, address caller);

  using SafeMath for uint256;

  address public immutable lendingPool;
  address public immutable router;
  address public immutable rnbw;
  address public immutable vestingContract;
  address public immutable curveFactory;
  address public immutable USDC;
  address public WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  constructor(
    address _lendingPool,
    address _router,
    address _rnbw,
    address _vestingContract,
    address _curveFactory,
    address _usdc
  ) public {
    lendingPool = _lendingPool;
    router = _router;
    rnbw = _rnbw;
    vestingContract = _vestingContract;
    curveFactory = _curveFactory;
    USDC = _usdc;
  }

  function buybackRnbw(address[] calldata _underlyings) external onlyOwner returns (uint256) {
    uint256 rnbwBought;

    for (uint256 i = 0; i < _underlyings.length; i++) {
      uint256 underlyingAmount =
        ILendingPool(lendingPool).withdraw(_underlyings[i], type(uint256).max, address(this));
      convertToUsdc(_underlyings[i], underlyingAmount);
    }

    uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));

    //approve uniswap to swap
    IERC20(USDC).approve(router, usdcBalance);

    //create swap path
    address[] memory path = new address[](3);
    path[0] = USDC;
    path[1] = WETH9;
    path[2] = rnbw;
    rnbwBought = IUniswapV2Router02(router).swapExactTokensForTokens(
      usdcBalance,
      0,
      path,
      address(this),
      block.timestamp + 60
    )[0];

    emit RnbwBought(rnbwBought, msg.sender);
    return rnbwBought;
  }

  function convertToUsdc(address _underlying, uint256 _underlyingAmount)
    internal
    returns (uint256)
  {
    address curveAddress = ICurveFactory(curveFactory).getCurve(_underlying, USDC);
    IERC20(_underlying).approve(curveAddress, _underlyingAmount);
    uint256 targetAmount =
      ICurve(curveAddress).originSwap(
        _underlying,
        USDC,
        _underlyingAmount,
        0,
        block.timestamp + 60
      );
    return targetAmount;
  }

  function sendToVestingContract() external onlyOwner {
    uint256 rnbwAmount = IERC20(rnbw).balanceOf(address(this));
    IERC20(rnbw).transfer(vestingContract, rnbwAmount);
    emit RnbwSentToVesting(rnbwAmount, msg.sender);
  }

  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'Only EOA allowed');
    _;
  }
}
