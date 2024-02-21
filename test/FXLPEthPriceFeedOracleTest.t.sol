pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {LendingMarketTestHelper, IOracle, IAssimilator} from './LendingMarketTestHelper.t.sol';
import {FXLPEthPriceFeedOracle, IFXPool, IAggregatorV3Interface} from '../contracts/xave-oracles/FXLPEthPriceFeedOracle.sol';
import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';

contract FXLPEthPriceFeedOracleTest is Test, LendingMarketTestHelper {
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

  function testLpTokenPrice() public {
    _deployReserve();
    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);
    int256 lpPrice = IHLPOracle(lpOracle).latestAnswer();
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
    uint256 tokenPriceInAaveOracle = (IAaveOracle(aaveOracle).getAssetPrice(IHLPOracle(lpOracle).baseContract()));

    assertEq(tokenPriceInAaveOracle, uint256(lpPrice));
    assertEq(lpOracle, IAaveOracle(aaveOracle).getSourceOfAsset(IHLPOracle(lpOracle).baseContract()));

    // console2.log('lpPrice', uint256(lpPrice));
    // console2.log('baseContract', IHLPOracle(lpOracle).baseContract());
    // console2.log('ETC/USD price', uint256(IHLPOracle(IHLPOracle(lpOracle).quotePriceFeed()).latestAnswer()));
  }

  function testLpPriceCalculation() public {
    _deployReserve();
    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);
    int256 initialOraclePrice = IHLPOracle(lpOracle).latestAnswer();
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
    uint256 tokenPriceInAaveOracle = (IAaveOracle(aaveOracle).getAssetPrice(IHLPOracle(lpOracle).baseContract()));

    uint256 initialSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 initialLiquidity, uint256[] memory individualLiquidity) = IFXPool(LP_XSGD).liquidity();

    vm.startPrank(me);
    IERC20(USDC).approve(BALANCER_VAULT, type(uint256).max);
    IERC20(XSGD).approve(BALANCER_VAULT, type(uint256).max);
    vm.stopPrank();

    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);
    // fees will be zero after deposit

    uint256 initialLPBalance = IERC20(LP_XSGD).balanceOf(me);
    uint256 usdcAfterDeposit = IERC20(USDC).balanceOf(me);
    uint256 xsgdAfterDeposit = IERC20(XSGD).balanceOf(me);
    int256 initialPriceAfterDeposit = IHLPOracle(lpOracle).latestAnswer();

    _loopSwapsExact(100, 10_000, lpOracle, false, me);
    int256 oraclePriceBeforeMint = IHLPOracle(lpOracle).latestAnswer();

    // trigger mint fees without affecting supply
    _removeLiquidity(IFXPool(LP_XSGD).getPoolId(), 1, me, USDC, XSGD);

    (uint256 postBurnLiquidity, uint256[] memory postBurnIndividualLiquidity) = IFXPool(LP_XSGD).liquidity();

    assertEq(IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire(), 0);

    // oraclePriceBeforeFeeMint vs oraclePriceAfterFeeMint
    console2.log(oraclePriceBeforeMint);

    assertEq(oraclePriceBeforeMint, IHLPOracle(lpOracle).latestAnswer());

    console.log('initial liquidity', initialLiquidity);
    console.log('postBurnLiquidity: ', postBurnLiquidity);
  }

  function testFuzzLpPriceCalculation(uint256 loopTimes) public {
    vm.assume(loopTimes < 2000);
    _deployReserve();
    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);
    int256 initialOraclePrice = IHLPOracle(lpOracle).latestAnswer();
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
    uint256 tokenPriceInAaveOracle = (IAaveOracle(aaveOracle).getAssetPrice(IHLPOracle(lpOracle).baseContract()));

    uint256 initialSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 initialLiquidity, uint256[] memory individualLiquidity) = IFXPool(LP_XSGD).liquidity();

    vm.startPrank(me);
    IERC20(USDC).approve(BALANCER_VAULT, type(uint256).max);
    IERC20(XSGD).approve(BALANCER_VAULT, type(uint256).max);
    vm.stopPrank();

    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);
    // fees will be zero after deposit

    uint256 initialLPBalance = IERC20(LP_XSGD).balanceOf(me);
    uint256 usdcAfterDeposit = IERC20(USDC).balanceOf(me);
    uint256 xsgdAfterDeposit = IERC20(XSGD).balanceOf(me);
    int256 initialPriceAfterDeposit = IHLPOracle(lpOracle).latestAnswer();

    _loopSwapsExact(loopTimes, 10_000, lpOracle, false, me);
    int256 oraclePriceBeforeMint = IHLPOracle(lpOracle).latestAnswer();

    // trigger mint fees without affecting supply
    _removeLiquidity(IFXPool(LP_XSGD).getPoolId(), 1, me, USDC, XSGD);

    (uint256 postBurnLiquidity, uint256[] memory postBurnIndividualLiquidity) = IFXPool(LP_XSGD).liquidity();

    assertEq(IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire(), 0);

    // oraclePriceBeforeFeeMint vs oraclePriceAfterFeeMint
    assertEq(oraclePriceBeforeMint, IHLPOracle(lpOracle).latestAnswer());

    console.log('initial liquidity', initialLiquidity);
    console.log('postBurnLiquidity: ', postBurnLiquidity);
  }

  //   function testExploitLP() public {
  //     address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

  //     vm.startPrank(me);
  //     IERC20(USDC).approve(BALANCER_VAULT, type(uint256).max);
  //     IERC20(XSGD).approve(BALANCER_VAULT, type(uint256).max);
  //     vm.stopPrank();
  //     uint256 initialOraclePrice = uint256(IOracle(lpOracle).latestAnswer());

  //     (uint256 initialLiquidity, uint256[] memory individualLiquidity) = IFXPool(LP_XSGD).liquidity();

  //     uint256 initialTotalSupply = IFXPool(LP_XSGD).totalSupply();

  //     uint256 usdcBeforeDeposit = IERC20(USDC).balanceOf(me);
  //     uint256 xsgdBeforeDeposit = IERC20(XSGD).balanceOf(me);

  //     // 1 - add 100k liquidity
  //     // can be flashloaned
  //     _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);

  //     uint256 initialLPBalance = IERC20(LP_XSGD).balanceOf(me);
  //     // uint256 usdcAfterDeposit = IERC20(USDC).balanceOf(me);
  //     // uint256 xsgdAfterDeposit = IERC20(XSGD).balanceOf(me);

  // uint256 lpPriceBeforeBurn = uint256(IOracle(lpOracle).latestAnswer());
  // // remove the liquidity, mint protocol fees, inflate totalSupply
  // _removeLiquidity(IFXPool(LP_XSGD).getPoolId(), initialLPBalance, me, USDC, XSGD);

  //     uint256 lpPriceBeforeBurn = uint256(IOracle(lpOracle).latestAnswer());
  //     console.log('unclaimed fees in numeraire before burn', IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire());
  //     // remove the liquidity, mint protocol fees, inflate totalSupply
  //     // _removeLiquidity(IFXPool(LP_XSGD).getPoolId(), initialLPBalance, me, USDC, XSGD);
  //     _removeLiquidity(IFXPool(LP_XSGD).getPoolId(), 1, me, USDC, XSGD);
  //     assertEq(IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire(), 0);

  //     // trigger without inflating supply
  //     (uint256 postLiquidity, uint256[] memory postIndLiquidity) = IFXPool(LP_XSGD).liquidity();
  //     uint256 usdcAfterBurn = IERC20(USDC).balanceOf(me);
  //     uint256 xsgdAfterBurn = IERC20(XSGD).balanceOf(me);

  //     console.log('initial liquidity', initialLiquidity);
  //     console.log('initial base liquidity: ', individualLiquidity[0]);
  //     console.log('initial quote liquidity: ', individualLiquidity[1]);
  //     console.log('post liquidity', postLiquidity);
  //     console.log('post base liquidity: ', postIndLiquidity[0]);
  //     console.log('post quote liquidity: ', postIndLiquidity[1]);
  //     console.log('initial oracle price', initialOraclePrice);
  //     console.log('oracle price before burn', lpPriceBeforeBurn);
  //     console.log('oracle price after burn', uint256(IOracle(lpOracle).latestAnswer())); // higher
  //     console.log('initial total supply', initialTotalSupply);
  //     console.log('total supply after burn', IFXPool(LP_XSGD).totalSupply());
  //     console.log('protocolPercentFee', IFXPool(LP_XSGD).protocolPercentFee());
  //     /**

  //

  //     // LP Balances
  //     console.log('gain in liq: ', postLiquidity - initialLiquidity);
  //     console.log('gain in base liq: ', postIndLiquidity[0] - individualLiquidity[0]);
  //     console.log('gain in quote liq: ', postIndLiquidity[1] - individualLiquidity[1]);

  //     // user: me
  //     console.log('gain in usdcBalance: ', (usdcAfterBurn - usdcBeforeDeposit) / 1e6);
  //     console.log('gain in xsgdBalance: ', (xsgdAfterBurn - xsgdBeforeDeposit) / 1e6);
  //   }

  function __testPriceManipulation() private {
    _deployReserve();

    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    _doSwap(me, 130_000 * 1e6, USDC, XSGD);
    _loopSwaps(6, 10_000, lpOracle, true, me);
  }

  function testUnclaimedFees() public {
    _deployReserve();

    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);
    int256 oraclePriceBeforeSwaps = IOracle(lpOracle).latestAnswer();

    uint256 initialSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 initialLiquidity, ) = IFXPool(LP_XSGD).liquidity();

    uint256 initial = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
    console2.log('before loop unclaimed fees: ', initial);
    _loopSwaps(247, 10_000, address(lpOracle), true, me);

    // trigger minting
    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 10 * 1e18, me, USDC, XSGD);

    uint256 endSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 endLiquidity, ) = IFXPool(LP_XSGD).liquidity();

    int256 oraclePriceAfterSwaps = IOracle(lpOracle).latestAnswer();

    console2.log('end liquidity', endLiquidity);
    console2.log('end supply', endSupply);
    console2.log('supply diff', endSupply - initialSupply);
    console2.log('liquidity diff', endLiquidity - initialLiquidity);
    console2.log('after loop unclaimed fees: ', IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire());
    assertEq(IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire(), 0);
    assertGt(endLiquidity, initialLiquidity);
    assertGt(endSupply, initialSupply);
    assertGt(oraclePriceAfterSwaps, oraclePriceBeforeSwaps);
  }

  function testFuzzLoopTimesUnclaimedFees(uint256 loopTimes) public {
    vm.assume(loopTimes < 247);
    vm.assume(loopTimes > 12);

    _deployReserve();

    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    uint256 initialSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 initialLiquidity, ) = IFXPool(LP_XSGD).liquidity();

    uint256 initial = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
    console2.log('before loop unclaimed fees: ', initial);
    _loopSwaps(loopTimes, 10_000, address(lpOracle), true, me);

    // trigger minting
    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 10 * 1e18, me, USDC, XSGD);

    uint256 endSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 endLiquidity, ) = IFXPool(LP_XSGD).liquidity();

    console2.log('end liquidity', endLiquidity);
    console2.log('end supply', endSupply);
    console2.log('supply diff', endSupply - initialSupply);
    console2.log('liquidity diff', endLiquidity - initialLiquidity);
    console2.log('after loop unclaimed fees: ', IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire());
    assertEq(IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire(), 0);
    assertGt(endLiquidity, initialLiquidity);
    assertGt(endSupply, initialSupply);
  }

  // @TODO write a test that compares the price of the LP token at different pool ratios:
  //       - 50% : 50%
  //       - 80% : 20% (halts)
  //       - 20% : 80% (halts) - Current pool ratio at start
  function testLPTokenPriceComparisonAtDifferentPoolRatio() public {
    _deployReserve();

    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    uint256 startLpPrice = _getLPOraclePrice(LP_XSGD);

    (
      uint256 fiftyFiftyPoolRatioLpPriceBefore,
      uint256 fiftyFiftyPoolRatioLpPriceAfter
    ) = __testLPTokenPriceComparisonAtPoolRatio(170_120, USDC, XSGD);

    uint256 fiftyFiftyPrice = _getLPOraclePrice(LP_XSGD);

    uint256 fiftyFiftyPoolRatioLpPriceDiffPercentage = ((fiftyFiftyPrice - startLpPrice) * 1e18) / startLpPrice;

    console2.log('fiftyFiftyPrice', fiftyFiftyPrice);
    console.log('[From 20:80 to 50:50 LP Price] 1e-3:', fiftyFiftyPoolRatioLpPriceDiffPercentage / 1e11); // 0.0006

    (
      uint256 eightyTwentyPoolRatioLpPriceBefore,
      uint256 eightyTwentyPoolRatioLpPriceAfter
    ) = __testLPTokenPriceComparisonAtPoolRatio(152_000, USDC, XSGD);

    uint256 eightyTwentyPrice = _getLPOraclePrice(LP_XSGD);

    uint256 eightyTwentyPoolRatioLpPriceDiffPercentage = ((eightyTwentyPrice - fiftyFiftyPrice) * 1e18) /
      fiftyFiftyPrice;

    console2.log('eightyTwentyPrice', eightyTwentyPrice);
    console2.log('[From 50:50 to 80:20 LP Price] 1e-3:', eightyTwentyPoolRatioLpPriceDiffPercentage / 1e11);

    (
      uint256 twentyEightyPoolRatioLpPriceBefore,
      uint256 twentyEightyPoolRatioLpPriceAfter
    ) = __testLPTokenPriceComparisonAtPoolRatio(434_200, XSGD, USDC);

    uint256 twentyEightyPrice = _getLPOraclePrice(LP_XSGD);

    uint256 twentyEightyPoolRatioLpPriceDiffPercentage = ((eightyTwentyPrice - twentyEightyPrice) * 1e18) /
      eightyTwentyPrice; // due to math underflow, we reverse for absolute value

    console2.log('twentyEightyPrice', twentyEightyPrice);
    console2.log('[From 80:20 to 20:80 LP Price] 1e-3:', twentyEightyPoolRatioLpPriceDiffPercentage / 1e11);
  }

  function __testLPTokenPriceComparisonAtPoolRatio(
    uint256 _amountToSwap,
    address tokenA,
    address tokenB
  ) private returns (uint256, uint256) {
    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    int256 lpPriceBefore = IOracle(lpOracle).latestAnswer();

    // Get pool ratio prior to looping swaps
    (uint256 tokenAPercentage, uint256 tokenBPercentage) = _getPoolTokenRatio(IFXPool(LP_XSGD).getPoolId());
    (uint256 totalLiq2, uint256[] memory indivLiq2) = IFXPool(LP_XSGD).liquidity();

    console2.log('liq A * 100 \\ B\t\t', (indivLiq2[0] * 100) / indivLiq2[1], '%');
    console2.log('liq B * 100 \\ A\t\t', (indivLiq2[1] * 100) / indivLiq2[0], '%');

    _doSwap(me, _amountToSwap * 1e6, tokenA, tokenB);

    {
      (uint256 tokenAPercentage, uint256 tokenBPercentage) = _getPoolTokenRatio(IFXPool(LP_XSGD).getPoolId());

      console.log('after tokenAPercentage token A ratio', tokenAPercentage);
      console.log('after tokenBPercentage token B ratio', tokenBPercentage);

      (uint256 totalLiq2, uint256[] memory indivLiq2) = IFXPool(LP_XSGD).liquidity();

      console2.log('liq A * 100 \\ B\t\t', (indivLiq2[0] * 100) / indivLiq2[1], '%');
      console2.log('liq B * 100 \\ A\t\t', (indivLiq2[1] * 100) / indivLiq2[0], '%');
    }

    int256 lpPriceAfter = IOracle(lpOracle).latestAnswer();

    return (uint256(lpPriceBefore), uint256(lpPriceAfter));
  }

  function _viewWithdraw(uint256 tokensToBurn) internal returns (uint256 tA, uint256 tB) {
    uint256[] memory tokensReturned = IFXPoolExtra(LP_XSGD).viewWithdraw(tokensToBurn);
    // [0] base, [1] quote
    tA = tokensReturned[0]; // base
    tB = tokensReturned[1]; // quote

    console2.log('getRate ', IAssimilator(XSGD_ASSIM).getRate());
    console2.log('eth usd: ', uint256(IOracle(ETH_USD_ORACLE).latestAnswer()));
    console2.log('_viewWithdraw tA RAW: ', tA);
    console2.log('_viewWithdraw tA NUMERAIRE ', _convertToNumeraire(tA, XSGD_ASSIM));
    console2.log('_viewWithdraw tB RAW: ', tB);
    console2.log('_viewWithdraw tB NUMERAIRE: ', _convertToNumeraire(tB, USDC_ASSIM));

    uint256 totalNumeraireAmount = _convertToNumeraire(tA, XSGD_ASSIM) + _convertToNumeraire(tB, USDC_ASSIM);

    console.log('_viewWithdraw  totalNumeraireAmount', totalNumeraireAmount);
    console.log(
      '_viewWithdraw oracle price',
      ((((((totalNumeraireAmount * 1e18) / uint256(IOracle(ETH_USD_ORACLE).latestAnswer())))) * 1e18) / tokensToBurn) /
        1e10
    );
  }
}

interface IHLPOracle {
  function baseContract() external view returns (address);

  function quotePriceFeed() external view returns (address);

  function latestAnswer() external view returns (int256);
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

interface IFXPoolExtra {
  function viewWithdraw(uint256) external view returns (uint256[] memory);
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}
