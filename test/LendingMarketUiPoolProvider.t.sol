pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {LendingMarketTestHelper, IOracle, IAssimilator} from './LendingMarketTestHelper.t.sol';
import {FXLPEthPriceFeedOracle, IFXPool, IAggregatorV3Interface} from '../contracts/xave-oracles/FXLPEthPriceFeedOracle.sol';
import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {IHaloUiPoolDataProvider} from '../contracts/misc/interfaces/IHaloUiPoolDataProvider.sol';

contract LendingMarketUiPoolProvider is Test, LendingMarketTestHelper {
  // Buildbear
  address constant LP_ADDRESS_PROVIDER_ADD = 0x3af74d19F50f24C75e4000Fe665d718387b1DA74;
  address constant UI_POOL_PROVIDER_ADD = 0x8E330219fc45A5CE56a4CEa47A2D49b73De29994;

  address constant P_UI_PROV = 0x755E39Ba1a425548fF8990A5c223C34C5ce5f8a5;
  address constant P_ADD_PROV = 0x68aeB9C8775Cfc9b99753A1323D532556675c555;

  // tenderly
  //   address constant LP_ADDRESS_PROVIDER_ADD = 0x94b169a5c6365C83E040d0b127A334B40062430F;
  //   address constant UI_POOL_PROVIDER_ADD = 0xD256ee8Bb9B7296fD4641FaF8ABb785333B3ED41;

  function setUp() public {
    vm.createSelectFork('https://rpc.buildbear.io/xclabs');
    // vm.createSelectFork('https://polygon-mainnet.g.alchemy.com/v2/0I8FwezsNv5eoYaAt0z035w2m8rHH_Kr');
    // vm.createSelectFork('https://rpc.tenderly.co/fork/98ab2b22-7a39-4fcf-b4ad-1cc8f1c80a59');
  }

  function testUiProvider() public {
    (IHaloUiPoolDataProvider.AggregatedReserveData[] memory reservesData, ) = IHaloUiPoolDataProvider(
      UI_POOL_PROVIDER_ADD
    ).getReservesData(ILendingPoolAddressesProvider(LP_ADDRESS_PROVIDER_ADD));

    // console2.log(UiProvider(UI_POOL_PROVIDER_ADD).networkBaseTokenPriceInUsdProxyAggregator());
    // console2.log(UiProvider(UI_POOL_PROVIDER_ADD).marketReferenceCurrencyPriceInUsdProxyAggregator());

    // console.log(UiProvider(UI_POOL_PROVIDER_ADD).ETH_CURRENCY_UNIT());
    console2.log(reservesData[0].name);
  }

  //   function testUiProviderPolygon() public {
  //     // (IHaloUiPoolDataProvider.AggregatedReserveData[] memory reservesData, ) = IHaloUiPoolDataProvider(
  //     //   UI_POOL_PROVIDER_ADD
  //     // ).getReservesData(ILendingPoolAddressesProvider(LP_ADDRESS_PROVIDER_ADD));

  //     console2.log(UiProvider(P_UI_PROV).networkBaseTokenPriceInUsdProxyAggregator());
  //     console2.log(UiProvider(P_UI_PROV).marketReferenceCurrencyPriceInUsdProxyAggregator());

  //     // console.log(UiProvider(UI_POOL_PROVIDER_ADD).ETH_CURRENCY_UNIT());
  //     // console2.log(reservesData[0].name);
  //   }
}

interface UiProvider {
  function ETH_CURRENCY_UNIT() external view returns (uint256);

  function networkBaseTokenPriceInUsdProxyAggregator() external view returns (address);

  function marketReferenceCurrencyPriceInUsdProxyAggregator() external view returns (address);
}
