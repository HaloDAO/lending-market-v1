pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';

import 'forge-std/console2.sol';

import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';


import {LendingMarketTestHelper} from './LendingMarketTestHelper.t.sol';
import {hlpPriceFeedOracle, hlpContract, AggregatorV3Interface} from './HLPPriceFeedOracle.sol';

// interface IOracle {
//   function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

//   function latestAnswer() external view returns (int256);
// }

contract HLPPriceFeedOracle is Test, LendingMarketTestHelper {
  // address constant LENDINPOOL_PROXY_ADDRESS = 0x78a5B2B028Fa6Fb0862b0961EB5131C95273763B;
  // address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  // address constant USDC_HOLDER = 0xf89d7b9c864f589bbF53a82105107622B35EaA40;
  // address constant XSGD = 0xDC3326e71D45186F113a2F448984CA0e8D201995;
  string private RPC_URL = vm.envString('POLYGON_RPC_URL');
  
  // uint256 constant FORK_BLOCK = 52764552;
  // address constant LP_XSGD = 0xE6D8FcD23eD4e417d7e9D1195eDf2cA634684e0E;
  // address constant LENDINGPOOL_ADDRESS_PROVIDER = 0x68aeB9C8775Cfc9b99753A1323D532556675c555;
  // address constant XSGD_HOLDER = 0x728C6f69B4EaB57A9f2dE0Cf8Fd170eE5f22Eb21;
  // address constant ETH_USD_ORACLE = 0xF9680D99D6C9589e2a93a78A04A279e509205945;

  // address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  // address constant XAVE_TREASURY = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;
  // ILendingPool constant LP = ILendingPool(LENDINPOOL_PROXY_ADDRESS);
  // address me = address(this);

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);

    vm.prank(XSGD_HOLDER);
    IERC20(XSGD).transfer(me, 5_000_000 * 1e6);
    vm.prank(USDC_HOLDER);
    IERC20(USDC).transfer(me, 5_000_000 * 1e6);
  }

  /***

## !!! HLP Oracle FXPool ratio manipulation scenario (assumptions) !!!

- Start state FXPool 40% XSGD / 60% USDC
- Bob deposits XSGD / USDC LP tokens as collateral into LendingPool
- Bob draws USDC loan against his LP tokens
- Lending Pool marks his LTV at 60% relative to his collateral
- 1 TX
-     Swap: Sells XSGD into FXPool (XSGD/USDC) takes it out of BETA
-     FXPool state: 80% XSGD / 20% USDC
-     Question
-     Calls `liquidationCall` on the lendingPool
-     Lending Pool checks price of LP token
-     Price has changed

 */

  function testLpTokenPrice() public {
    _deployReserve();
    address lpOracle = _deployAndSetLPOracle();
    int256 lpPrice = IHLPOracle(lpOracle).latestAnswer();
    console.log('lpPrice', uint256(lpPrice));
    console2.log('baseContract', IHLPOracle(lpOracle).baseContract());
    console2.log('ETC/USD price', uint256(IHLPOracle(IHLPOracle(lpOracle).quotePriceFeed()).latestAnswer()));
  }

  function __testPriceManipulation() private {
    // OPS: [noop] Remove OR Disable the curve / HLP XSGD/USDC from the lending pool
    // [DONE] add LP XSGD/USDC to the lending pool
    //    - deploy AToken Implementation
    //    - deploy StableDebtToken (optional?)
    //    - deploy VariableDebtToken
    //    - deploy DefaultReserveInterestStrategy
    // output:
    //     ratio of tokens @TODO
    //     liquidity @TODO
    //     [DONE] price of XSGD/USDC LP token according to HLPOracle
    // swap XSGD for USDC @TODO
    // output: price of XSGD/USDC LP token according to HLPOracle @TODO

    // DataTypes.ReserveData memory rd = LP.getReserveData();
    // console2.log('rd.liquidityIndex', uint256(rd.liquidityIndex));

    _deployReserve();

    address lpOracle = _deployAndSetLPOracle();

    // address[] memory rvs = LP.getReservesList();
    // console2.log('rvs', rvs.length);
    // console2.log('rvs 7', rvs[7]); // XSGD HLP

    // IFXPool(LP_XSGD).viewParameters();
    // lp price in eth 452141146999509

    _doSwap(me, 130_000 * 1e6, USDC, XSGD);

    // _swapAndCheck(lpOracle, 230_000 * 1e6, XSGD, USDC, 'SWAP 1');
    // _swapAndCheck(lpOracle, 230_000 * 1e6, USDC, XSGD, 'SWAP 2');

    _swapAndCheck(lpOracle, 10_000 * 1e6, XSGD, USDC, 'SWAP 1');
    //lp price in eth  452141146997922
    _swapAndCheck(lpOracle, 10_000 * 1e6, USDC, XSGD, 'SWAP 2');
    // lp price in eth 455721063474353
    _swapAndCheck(lpOracle, 10_000 * 1e6, XSGD, USDC, 'SWAP 3');
    // lp price in eth 455721063472831
    _swapAndCheck(lpOracle, 10_000 * 1e6, USDC, XSGD, 'SWAP 4');

    _swapAndCheck(lpOracle, 10_000 * 1e6, XSGD, USDC, 'SWAP 5');
    //lp price in eth  452141146997922
    _swapAndCheck(lpOracle, 10_000 * 1e6, USDC, XSGD, 'SWAP 6');
    // lp price in eth 455721063474353
    _swapAndCheck(lpOracle, 10_000 * 1e6, XSGD, USDC, 'SWAP 7');
    // lp price in eth 455721063472831
    _swapAndCheck(lpOracle, 10_000 * 1e6, USDC, XSGD, 'SWAP 8');

    _swapAndCheck(lpOracle, 10_000 * 1e6, XSGD, USDC, 'SWAP 9');
    //lp price in eth  452141146997922
    _swapAndCheck(lpOracle, 10_000 * 1e6, USDC, XSGD, 'SWAP 10');
    // lp price in eth 455721063474353
    _swapAndCheck(lpOracle, 10_000 * 1e6, XSGD, USDC, 'SWAP 11');
    // lp price in eth 455721063472831
    _swapAndCheck(lpOracle, 10_000 * 1e6, USDC, XSGD, 'SWAP 12');

    // {
    //   console2.log('minting protocol fees');
    //   uint256 tsB4 = IFXPool(LP_XSGD).totalSupply();
    //   _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 11 * 1e18, me, USDC, XSGD);
    //   console2.log('totalSupply minted:', IFXPool(LP_XSGD).totalSupply() - tsB4);
    // }
    // _swapAndCheck(lpOracle, 100_000 * 1e6, XSGD, USDC, 'SWAP 13');

    // lp price in eth 456793395455523
    // Note: the protocol does not get fees if the user swaps towards beta after getting out of beta. the reward for that swap goes to the user
  }

  function testOverloadUnclaimedFees() public {
    _deployReserve();

    address lpOracle = _deployAndSetLPOracle();

    // address[] memory rvs = LP.getReservesList();
    // console2.log('rvs', rvs.length);
    // console2.log('rvs 7', rvs[7]); // XSGD HLP

    // IFXPool(LP_XSGD).viewParameters();
    // lp price in eth 452141146999509

    // _doSwap(me, 130_000 * 1e6, USDC, XSGD);
    uint256 initialSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 initialLiquidity, ) = IFXPool(LP_XSGD).liquidity();

    uint256 initial = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
    console2.log('before loop: ', initial);
    _loopSwaps(247, 10_000, address(lpOracle));

    _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 10 * 1e18, me, USDC, XSGD);

    uint256 endSupply = IFXPool(LP_XSGD).totalSupply();
    (uint256 endLiquidity, ) = IFXPool(LP_XSGD).liquidity();

    console2.log('end liquidity', endLiquidity);
    console2.log('end supply', endSupply);

    console2.log('supply diff', endSupply - initialSupply);
    console2.log('liquidity diff', endLiquidity - initialLiquidity);

    console2.log('after loop unclaimed fees: ', IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire());
  }

  // ERC20 helper functions copied from balancer-core-v2 ERC20Helpers.sol
  // function _asIAsset(address[] memory addresses) internal pure returns (IAsset[] memory assets) {
  //   // solhint-disable-next-line no-inline-assembly
  //   assembly {
  //     assets := addresses
  //   }
  // }
}

// function swapInFXPool() private {}

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

interface IOracle {
  function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

  function latestAnswer() external view returns (int256);
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}
