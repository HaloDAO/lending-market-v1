// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import "forge-std/console.sol";

import "@bot/aave-v2/FlashMintLiquidatorBorrowRepayAave.sol";

contract AaveV2LiquidationTest is Test {
    function test() public {
        console.log("AaveV2LiquidationTest.test()");
    }
}
