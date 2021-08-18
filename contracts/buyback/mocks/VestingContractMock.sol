// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

contract VestingContractMock is ERC20('Rainbow Pool', 'xRNBW') {
  using SafeMath for uint256;
  IERC20 public immutable rnbw;
  uint256 public constant DECIMALS = 1e18;

  constructor(IERC20 _rnbw) public {
    rnbw = _rnbw;
  }

  function enter(uint256 _amount) public {
    uint256 totalRnbw = rnbw.balanceOf(address(this));
    uint256 totalShares = totalSupply();
    if (totalShares == 0 || totalRnbw == 0) {
      _mint(msg.sender, _amount);
    } else {
      uint256 xRnbwAmount = _amount.mul(totalShares).div(totalRnbw);
      _mint(msg.sender, xRnbwAmount);
    }
    rnbw.transferFrom(msg.sender, address(this), _amount);
  }

  function leave(uint256 _share) public {
    uint256 totalShares = totalSupply();
    uint256 rnbwAmount = _share.mul(rnbw.balanceOf(address(this))).div(totalShares);
    _burn(msg.sender, _share);
    rnbw.transfer(msg.sender, rnbwAmount);
  }

  function getCurrentXRnbwPrice() public view returns (uint256) {
    uint256 totalShares = totalSupply();
    require(totalShares > 0, 'No xRnbw supply');
    uint256 xRnbwPrice = rnbw.balanceOf(address(this)).mul(DECIMALS).div(totalShares);
    return xRnbwPrice;
  }
}
