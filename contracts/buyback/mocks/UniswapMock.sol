pragma solidity >=0.6.2;

import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

contract UniswapMock is IUniswapV2Router02 {
  using SafeMath for uint256;

  address rnbwToken;

  constructor(address _rnbwToken) public {
    rnbwToken = _rnbwToken;
  }

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts) {
    IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
    uint256 amountOut = amountIn.mul(2);
    IERC20(rnbwToken).transfer(msg.sender, amountOut);
    return [amountOut];
  }
}
