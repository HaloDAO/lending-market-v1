pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';

import {FXEthBasePriceFeedOracle} from 'contracts/xave-oracles/FXEthBasePriceFeedOracle.sol';
import {MockAggregator} from './helpers/MockAggregator.sol';

contract FXEthBasePriceFeedOracleTest is Test {
  function testFxEthBasePriceFeedOracle() public {
    MockAggregator baseAgg = new MockAggregator(74363817, 8); // sgd / usd
    MockAggregator quoteAgg = new MockAggregator(290559420916, 8); // eth / usd

    FXEthBasePriceFeedOracle oracle = new FXEthBasePriceFeedOracle(
      address(baseAgg),
      address(quoteAgg),
      18,
      'SGD / ETH (sgd-usd / eth-usd)'
    );

    (, int256 price, , , ) = oracle.latestRoundData();

    assertEq(price, 255933250298906, 'correct price');
  }
}
