pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {LendingMarketTestHelper} from './LendingMarketTestHelper.t.sol';
import {hlpPriceFeedOracle, hlpContract, AggregatorV3Interface} from './HLPPriceFeedOracle.sol';
import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';

contract HLPPriceFeedOracle is Test, LendingMarketTestHelper {
  string private RPC_URL = vm.envString('POLYGON_RPC_URL');

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);

    vm.prank(XSGD_HOLDER);
    IERC20(XSGD).transfer(me, 5_000_000 * 1e6);
    vm.prank(USDC_HOLDER);
    IERC20(USDC).transfer(me, 5_000_000 * 1e6);
  }

  function testLpTokenPrice() public {
    _deployReserve();
    address lpOracle = _deployAndSetLPOracle();
    int256 lpPrice = IHLPOracle(lpOracle).latestAnswer();
    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();
    uint256 tokenPriceInAaveOracle = (IAaveOracle(aaveOracle).getAssetPrice(IHLPOracle(lpOracle).baseContract()));

    assertEq(tokenPriceInAaveOracle, uint256(lpPrice));
    assertEq(lpOracle, IAaveOracle(aaveOracle).getSourceOfAsset(IHLPOracle(lpOracle).baseContract()));

    // console2.log('lpPrice', uint256(lpPrice));
    // console2.log('baseContract', IHLPOracle(lpOracle).baseContract());
    // console2.log('ETC/USD price', uint256(IHLPOracle(IHLPOracle(lpOracle).quotePriceFeed()).latestAnswer()));
  }

  function __testPriceManipulation() private {
    _deployReserve();

    address lpOracle = _deployAndSetLPOracle();

    _doSwap(me, 130_000 * 1e6, USDC, XSGD);
    _loopSwaps(6, 10_000, lpOracle, true);
  }

  function testUnclaimedFees() public {
    _deployReserve();

    address lpOracle = _deployAndSetLPOracle();

    uint256 initialSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 initialLiquidity, ) = IFXPool(LP_XSGD).liquidity();

    uint256 initial = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
    console2.log('before loop unclaimed fees: ', initial);
    _loopSwaps(247, 10_000, address(lpOracle), true);

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

  function testFuzz_FuzzLoopTimesUnclaimedFees(uint256 loopTimes) public {
    vm.assume(loopTimes < 247);
    vm.assume(loopTimes > 12);

    _deployReserve();

    address lpOracle = _deployAndSetLPOracle();

    uint256 initialSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 initialLiquidity, ) = IFXPool(LP_XSGD).liquidity();

    uint256 initial = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
    console2.log('before loop unclaimed fees: ', initial);
    _loopSwaps(loopTimes, 10_000, address(lpOracle), true);

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

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}
