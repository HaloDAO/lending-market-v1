// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {ICurveFactory} from '../interfaces/ICurveFactory.sol';

contract CurveFactoryMock is ICurveFactory {
  mapping(address => address) curveAddresses;

  address public immutable USDC;

  constructor(
    address _usdcAddress,
    address[] memory baseCurrencies,
    address[] memory baseCurrencyCurveAddresses
  ) public {
    USDC = _usdcAddress;
    for (uint256 i = 0; i < baseCurrencies.length; i++) {
      curveAddresses[baseCurrencies[i]] = baseCurrencyCurveAddresses[i];
    }
  }

  function getCurve(address _baseCurrency, address _quoteCurrency)
    external
    view
    override
    returns (address)
  {
    return _quoteCurrency == USDC ? curveAddresses[_baseCurrency] : address(0);
  }

  //mock function to simulate adding a new curve
  function newCurve(address baseCurrency, address baseCurrencyCurveAddress) external {
    curveAddresses[baseCurrency] = baseCurrencyCurveAddress;
  }
}
