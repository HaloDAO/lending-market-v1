// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICurveFactory {
  function getCurve(address _baseCurrency, address _quoteCurrency) external view returns (address);
}
