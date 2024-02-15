pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {LendingMarketTestHelper, IOracle, IAssimilator} from './LendingMarketTestHelper.t.sol';
import {FXEthPriceFeedOracle, FXPool, AggregatorV3Interface} from '../contracts/xave-oracles/FXEthPriceFeedOracle.sol';
import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';

contract FXEthPriceFeedOraclePriceManipulationTest is Test, LendingMarketTestHelper {
  string private RPC_URL = vm.envString('POLYGON_RPC_URL');
  address constant XSGD_ASSIM = 0xC933a270B922acBd72ef997614Ec46911747b799;
  address constant USDC_ASSIM = 0xfbdc1B9E50F8607E6649d92542B8c48B2fc49a1a;
  address user2 = address(uint160(uint256(keccak256(abi.encodePacked('user2')))));

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);

    vm.prank(XSGD_HOLDER);
    IERC20(XSGD).transfer(me, 2_000_000 * 1e6);
    vm.prank(USDC_HOLDER);
    IERC20(USDC).transfer(me, 2_000_000 * 1e6);

    vm.prank(XSGD_HOLDER);
    IERC20(XSGD).transfer(user2, 2_000_000 * 1e6);
    vm.prank(USDC_HOLDER);
    IERC20(USDC).transfer(user2, 2_000_000 * 1e6);
  }

  function _numerairePrice(uint256 _ethAmount) internal view returns (uint256) {
    (, int256 priceFeedVal, , , ) = AggregatorV3Interface(ETH_USD_ORACLE).latestRoundData();
    return (uint256(priceFeedVal) * _ethAmount) / 1e8;
  }

  function testLpPriceCalculation() public {
    _deployReserve();
    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    // move the ratio into the 10% : 90% range
    _doSwap(me, 134_000 * 1e6, XSGD, USDC);

    uint256 priceOracle1090 = uint256(IHLPOracle(lpOracle).latestAnswer());
    uint256 priceOracle1090_2 = uint256(IHLPOracle(lpOracle).latestAnswer2());
    uint256 priceOracle1090_3 = uint256(IHLPOracle(lpOracle).latestAnswer3());

    (uint256 totalLiq, uint256[] memory indivLiq) = IFXPool(LP_XSGD).liquidity();
    console2.log('priceOracle1090\t\t', priceOracle1090);
    console2.log('priceOracle1090_2\t\t', priceOracle1090_2);
    console2.log('priceOracle1090Num\t\t', _numerairePrice(priceOracle1090));
    console2.log('priceOracle1090_2Num\t\t', _numerairePrice(priceOracle1090_2));
    console2.log('totalLiq\t\t\t', totalLiq);
    console2.log('indivLiq[0]\t\t\t', indivLiq[0]);
    console2.log('indivLiq[1]\t\t\t', indivLiq[1]);
    console2.log('supply\t\t\t', IFXPool(LP_XSGD).totalSupply());
    console2.log('liq A * 100 \\ totalLiq\t', (indivLiq[0] * 100) / totalLiq, '%');
    console2.log('liq B * 100 \\ totalLiq\t', (indivLiq[1] * 100) / totalLiq, '%');

    // move the ratio into the 90% : 10% range
    _doSwap(me, 445_800 * 1e6, USDC, XSGD);
    (uint256 totalLiq2, uint256[] memory indivLiq2) = IFXPool(LP_XSGD).liquidity();
    uint256 priceOracle9010 = uint256(IHLPOracle(lpOracle).latestAnswer());
    uint256 priceOracle9010_2 = uint256(IHLPOracle(lpOracle).latestAnswer2());

    console2.log('----------------------------------\t\t');
    console2.log('priceOracle9010\t\t', priceOracle9010);
    console2.log('priceOracle9010_2\t\t', priceOracle9010_2);
    console2.log('priceOracle9010Num\t\t', _numerairePrice(priceOracle9010));
    console2.log('priceOracle9010_2Num\t\t', _numerairePrice(priceOracle9010_2));
    console2.log('totalLiq2\t\t\t', totalLiq2);
    console2.log('indivLiq2[0]\t\t\t', indivLiq2[0]);
    console2.log('indivLiq2[1]\t\t\t', indivLiq2[1]);
    console2.log('supply\t\t\t', IFXPool(LP_XSGD).totalSupply());
    console2.log('liq A * 100 \\ totalLiq2\t', (indivLiq2[0] * 100) / totalLiq2, '%');
    console2.log('liq B * 100 \\ totalLiq2\t', (indivLiq2[1] * 100) / totalLiq2, '%');
    // price difference %
    console2.log(
      'price difference %\t\t',
      (((priceOracle9010 - priceOracle1090) * 10_000) / priceOracle1090),
      ' (00%)'
    );
    console2.log(
      'price difference2 %\t\t',
      (((priceOracle9010_2 - priceOracle1090_2) * 10_000) / priceOracle1090_2),
      '(00%)'
    );

    // move the ratio into the 50% : 50% range
    _doSwap(me, 295_000 * 1e6, XSGD, USDC);
    (uint256 totalLiq3, uint256[] memory indivLiq3) = IFXPool(LP_XSGD).liquidity();
    uint256 priceOracle5050 = uint256(IHLPOracle(lpOracle).latestAnswer());
    uint256 priceOracle5050_2 = uint256(IHLPOracle(lpOracle).latestAnswer2());

    console2.log('----------------------------------\t\t');
    console2.log('priceOracle5050\t\t', priceOracle5050);
    console2.log('priceOracle5050_2\t\t', priceOracle5050_2);
    console2.log('priceOracle5050Num\t\t', _numerairePrice(priceOracle5050));
    console2.log('priceOracle5050_2Num\t\t', _numerairePrice(priceOracle5050_2));
    console2.log('totalLiq3\t\t\t', totalLiq3);
    console2.log('indivLiq3[0]\t\t\t', indivLiq3[0]);
    console2.log('indivLiq3[1]\t\t\t', indivLiq3[1]);
    console2.log('liq A * 100 \\ totalLiq3\t', (indivLiq3[0] * 100) / totalLiq3, '%');
    console2.log('liq B * 100 \\ totalLiq3\t', (indivLiq3[1] * 100) / totalLiq3, '%');
    // price difference %
    console2.log('price difference %\t\t', ((priceOracle9010 - priceOracle5050) * 10_000) / priceOracle5050, ' (00%)');
    console2.log(
      'price difference2 %\t\t',
      ((priceOracle9010_2 - priceOracle5050_2) * 10_000) / priceOracle5050_2,
      '(00%)'
    );
  }
}

interface IHLPOracle {
  function baseContract() external view returns (address);

  function quotePriceFeed() external view returns (address);

  function latestAnswer() external view returns (int256);

  function latestAnswer2() external view returns (int256);

  function latestAnswer3() external view returns (int256);
}

interface IFiatToken {
  function mint(address to, uint256 amount) external;

  function configureMinter(address minter, uint256 minterAllowedAmount) external;

  function masterMinter() external view returns (address);

  function increaseMinterAllowance(address _minter, uint256 _increasedAmount) external view;
}

interface IVault {
  function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;

  struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request) external;

  struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
  }

  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
   */
  event Swap(
    bytes32 indexed poolId,
    IERC20 indexed tokenIn,
    IERC20 indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }
}

interface IAsset {
  // solhint-disable-previous-line no-empty-blocks
}

interface IFXPool {
  struct Assimilator {
    address addr;
    uint8 ix;
  }

  function getPoolId() external view returns (bytes32);

  function protocolPercentFee() external view returns (uint256);

  function viewParameters() external view returns (uint256, uint256, uint256, uint256, uint256);

  // returns(totalLiquidityInNumeraire, individual liquidity)
  function liquidity() external view returns (uint256, uint256[] memory);

  function totalSupply() external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);

  function viewWithdraw(uint256) external view returns (uint256[] memory);
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}
