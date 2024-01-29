pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import {Vm} from 'forge-std/Vm.sol';
import 'forge-std/console2.sol';

import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {ILendingPool} from '../contracts/interfaces/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {AaveOracle} from '../contracts/misc/AaveOracle.sol';

import {MockAggregator} from '../contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {IHaloUiPoolDataProvider} from '../contracts/misc/interfaces/IHaloUiPoolDataProvider.sol';

import {DataTypes} from '../contracts/protocol/libraries/types/DataTypes.sol';
import {IAToken} from '../contracts/interfaces/IAToken.sol';
import {AToken} from '../contracts/protocol/tokenization/AToken.sol';
import {IAaveIncentivesController} from '../contracts/interfaces/IAaveIncentivesController.sol';
import {VariableDebtToken} from '../contracts/protocol/tokenization/VariableDebtToken.sol';
import {StableDebtToken} from '../contracts/protocol/tokenization/StableDebtToken.sol';
import {DefaultReserveInterestRateStrategy} from '../contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {ILendingPoolConfigurator} from '../contracts/interfaces/ILendingPoolConfigurator.sol';
import {LendingPoolConfigurator} from '../contracts/protocol/lendingpool/LendingPoolConfigurator.sol';

import {hlpPriceFeedOracle, hlpContract, AggregatorV3Interface} from './HLPPriceFeedOracle.sol';

interface IOracle {
  function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

  function latestAnswer() external view returns (int256);
}

contract HLPPriceFeedOracle is Test {
  address constant LENDINPOOL_PROXY_ADDRESS = 0x78a5B2B028Fa6Fb0862b0961EB5131C95273763B;
  address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address constant USDC_HOLDER = 0xf89d7b9c864f589bbF53a82105107622B35EaA40;
  address constant XSGD = 0xDC3326e71D45186F113a2F448984CA0e8D201995;
  string private RPC_URL = vm.envString('POLYGON_RPC_URL');
  uint256 constant FORK_BLOCK = 52764552;
  address constant LP_XSGD = 0xE6D8FcD23eD4e417d7e9D1195eDf2cA634684e0E;
  address constant LENDINGPOOL_ADDRESS_PROVIDER = 0x68aeB9C8775Cfc9b99753A1323D532556675c555;
  address constant XSGD_HOLDER = 0x728C6f69B4EaB57A9f2dE0Cf8Fd170eE5f22Eb21;
  address constant ETH_USD_ORACLE = 0xF9680D99D6C9589e2a93a78A04A279e509205945;

  address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  address constant XAVE_TREASURY = 0x235A2ac113014F9dcb8aBA6577F20290832dDEFd;
  ILendingPool constant LP = ILendingPool(LENDINPOOL_PROXY_ADDRESS);
  address me = address(this);

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
  function testPriceManipulation() public {
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
    console2.log('baseContract', IHLPOracle(lpOracle).baseContract());
    console2.log('quotePriceFeed', IHLPOracle(lpOracle).quotePriceFeed());

    // address[] memory rvs = LP.getReservesList();
    // console2.log('rvs', rvs.length);
    // console2.log('rvs 7', rvs[7]); // XSGD HLP

    // IFXPool(LP_XSGD).viewParameters();
    // lp price in eth 452141146999509

    _doSwap(me, 130_000 * 1e6, USDC, XSGD);

    _swapAndCheck(lpOracle, 230_000 * 1e6, XSGD, USDC, 'SWAP 1');
    _swapAndCheck(lpOracle, 230_000 * 1e6, USDC, XSGD, 'SWAP 2');

    // _swapAndCheck(lpOracle, 100_000 * 1e6, XSGD, USDC, 'SWAP 1');
    // //lp price in eth  452141146997922
    // _swapAndCheck(lpOracle, 100_000 * 1e6, USDC, XSGD, 'SWAP 2');
    // // lp price in eth 455721063474353
    // _swapAndCheck(lpOracle, 100_000 * 1e6, XSGD, USDC, 'SWAP 3');
    // // lp price in eth 455721063472831
    // _swapAndCheck(lpOracle, 100_000 * 1e6, USDC, XSGD, 'SWAP 4');

    // _swapAndCheck(lpOracle, 100_000 * 1e6, XSGD, USDC, 'SWAP 5');
    // //lp price in eth  452141146997922
    // _swapAndCheck(lpOracle, 100_000 * 1e6, USDC, XSGD, 'SWAP 6');
    // // lp price in eth 455721063474353
    // _swapAndCheck(lpOracle, 100_000 * 1e6, XSGD, USDC, 'SWAP 7');
    // // lp price in eth 455721063472831
    // _swapAndCheck(lpOracle, 100_000 * 1e6, USDC, XSGD, 'SWAP 8');

    // _swapAndCheck(lpOracle, 100_000 * 1e6, XSGD, USDC, 'SWAP 9');
    // //lp price in eth  452141146997922
    // _swapAndCheck(lpOracle, 100_000 * 1e6, USDC, XSGD, 'SWAP 10');
    // // lp price in eth 455721063474353
    // _swapAndCheck(lpOracle, 100_000 * 1e6, XSGD, USDC, 'SWAP 11');
    // // lp price in eth 455721063472831
    // _swapAndCheck(lpOracle, 100_000 * 1e6, USDC, XSGD, 'SWAP 12');

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

  function _swapAndCheck(
    address lpOracle,
    uint256 amountToSwap,
    address swapIn,
    address swapOut,
    string memory swapLabel
  ) internal {
    int256 lpEthPrice0 = IOracle(lpOracle).latestAnswer();
    console2.log('[%s] lpEthPrice0\t', swapLabel, uint256(lpEthPrice0));
    uint256 fees0 = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
    console2.log('[%s] fees0\t', swapLabel, fees0);

    (uint256 totalLiquidityInNumeraire0, uint256[] memory individualLiquidity0) = IFXPool(LP_XSGD).liquidity();
    console2.log('[%s] totalLiquidityInNumeraire0\t', swapLabel, totalLiquidityInNumeraire0);
    // console2.log('[%s] totalLiquidityInNumeraire0', swapLabel, totalLiquidityInNumeraire0 / 1e18);
    console2.log(
      '[%s] individualLiquidity0',
      swapLabel,
      individualLiquidity0[0] / 1e18,
      individualLiquidity0[1] / 1e18
    );
    // console2.log('[%s] individualLiquidity0', swapLabel, individualLiquidity0[0], individualLiquidity0[1]);

    _doSwap(me, amountToSwap, swapIn, swapOut);

    (uint256 totalLiquidityInNumeraire1, uint256[] memory individualLiquidity1) = IFXPool(LP_XSGD).liquidity();

    if (totalLiquidityInNumeraire0 < totalLiquidityInNumeraire1) {
      console2.log(
        '[%s] totalLiquidityInNumeraire ADDED\t',
        swapLabel,
        (totalLiquidityInNumeraire1 - totalLiquidityInNumeraire0) / 1e18
      );
    } else {
      console2.log(
        '[%s] totalLiquidityInNumeraire SUBTRACTED\t',
        swapLabel,
        (totalLiquidityInNumeraire0 - totalLiquidityInNumeraire1) / 1e18
      );
    }

    // console2.log('[%s] totalLiquidityInNumeraire1\t', swapLabel, totalLiquidityInNumeraire1 / 1e18);
    // console2.log(
    //   '[%s] individualLiquidity1',
    //   swapLabel,
    //   individualLiquidity1[0] / 1e18,
    //   individualLiquidity1[1] / 1e18
    // );
    // console2.log('[%s] individualLiquidity1', swapLabel, individualLiquidity1[0], individualLiquidity1[1]);

    int256 lpEthPrice1 = IOracle(lpOracle).latestAnswer();
    console2.log('[%s] lpEthPrice1\t', swapLabel, uint256(lpEthPrice1));
    console2.log('[%s] fees ADDED\t', swapLabel, IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire() - fees0);

    // {
    //   console2.log('minting protocol fees');
    //   uint256 tsB4 = IFXPool(LP_XSGD).totalSupply();
    //   _addLiquidity(IFXPool(LP_XSGD).getPoolId(), 11 * 1e18, me, USDC, XSGD);
    //   console2.log('totalSupply minted:', IFXPool(LP_XSGD).totalSupply() - tsB4);
    // }

    (uint256 totalLiquidityInNumeraire2, uint256[] memory individualLiquidity2) = IFXPool(LP_XSGD).liquidity();

    if (totalLiquidityInNumeraire1 < totalLiquidityInNumeraire2) {
      console2.log(
        '[%s] totalLiquidityInNumeraire ADDED\t',
        swapLabel,
        (totalLiquidityInNumeraire2 - totalLiquidityInNumeraire1) / 1e18
      );
    } else {
      console2.log(
        '[%s] totalLiquidityInNumeraire SUBTRACTED\t',
        swapLabel,
        (totalLiquidityInNumeraire1 - totalLiquidityInNumeraire2) / 1e18
      );
    }

    // console2.log('[%s] totalLiquidityInNumeraire1\t', swapLabel, totalLiquidityInNumeraire1 / 1e18);
    // console2.log(
    //   '[%s] individualLiquidity1',
    //   swapLabel,
    //   individualLiquidity1[0] / 1e18,
    //   individualLiquidity1[1] / 1e18
    // );
    // console2.log('[%s] individualLiquidity1', swapLabel, individualLiquidity1[0], individualLiquidity1[1]);
    uint256 fees1 = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
    int256 lpEthPrice2 = IOracle(lpOracle).latestAnswer();
    console2.log('[%s] lpEthPrice2\t', swapLabel, uint256(lpEthPrice2));
    console2.log('[%s] fees ADDED\t', swapLabel, IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire() - fees1);

    console2.log(swapLabel);
    console2.log('After fee minting: lpEthPrice2 - lpEthPrice1', lpEthPrice2 - lpEthPrice1);
    console2.log('After swap: lpEthPrice1 - lpEthPrice0', lpEthPrice1 - lpEthPrice0);
  }

  function _deployAndSetLPOracle() private returns (address) {
    hlpPriceFeedOracle lpOracle = new hlpPriceFeedOracle(
      hlpContract(LP_XSGD),
      AggregatorV3Interface(ETH_USD_ORACLE),
      'LPXSGD-USDC/ETH'
    );

    address aaveOracle = ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPriceOracle();

    address[] memory assets = new address[](1);
    assets[0] = LP_XSGD;
    address[] memory sources = new address[](1);
    sources[0] = address(lpOracle);

    address oracleOwner = AaveOracle(aaveOracle).owner();
    vm.prank(oracleOwner);
    AaveOracle(aaveOracle).setAssetSources(assets, sources);

    uint256 _price = AaveOracle(aaveOracle).getAssetPrice(LP_XSGD);

    console2.log('price', _price);

    return address(lpOracle);
  }

  function _deployReserve() private {
    (AToken at, StableDebtToken sdt, VariableDebtToken vdt) = _deployAaveTokens();
    DefaultReserveInterestRateStrategy dris = _deployDefaultReserveInterestStrategy();

    LendingPoolConfigurator lpc = LendingPoolConfigurator(
      ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator()
    );

    ILendingPoolConfigurator.InitReserveInput[] memory input = new ILendingPoolConfigurator.InitReserveInput[](1);
    input[0] = ILendingPoolConfigurator.InitReserveInput({
      aTokenImpl: address(at),
      stableDebtTokenImpl: address(sdt),
      variableDebtTokenImpl: address(vdt),
      underlyingAssetDecimals: IERC20Detailed(LP_XSGD).decimals(),
      interestRateStrategyAddress: address(dris),
      underlyingAsset: LP_XSGD,
      treasury: XAVE_TREASURY,
      incentivesController: address(0),
      underlyingAssetName: 'XSGD-USDC',
      aTokenName: 'aXSGD-USDC',
      aTokenSymbol: 'aXSGD-USDC',
      variableDebtTokenName: vdt.name(),
      variableDebtTokenSymbol: vdt.symbol(),
      stableDebtTokenName: sdt.name(),
      stableDebtTokenSymbol: sdt.symbol(),
      params: bytes('')
    });

    vm.prank(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getPoolAdmin());
    lpc.batchInitReserve(input);
  }

  function _deployDefaultReserveInterestStrategy() private returns (DefaultReserveInterestRateStrategy) {
    return
      new DefaultReserveInterestRateStrategy(
        ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER),
        0.9 * 1e27, // optimal utilization rate
        0 * 1e27, // baseVariableBorrowRate
        0.04 * 1e27, // variableRateSlope1
        0.60 * 1e27, // variableRateSlope2
        0.02 * 1e27, // stableRateSlope1
        0.60 * 1e27 // stableRateSlope2
      );
  }

  function _deployAaveTokens() private returns (AToken, StableDebtToken, VariableDebtToken) {
    AToken a = new AToken();
    a.initialize(
      LP,
      XAVE_TREASURY,
      LP_XSGD,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(LP_XSGD).decimals(),
      'aXSGD-USDC',
      'aXSGD-USDC',
      bytes('')
    );

    StableDebtToken sdt = new StableDebtToken();
    sdt.initialize(
      LP,
      LP_XSGD,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(LP_XSGD).decimals(),
      'sbtXSGD-USDC',
      'sbtXSGD-USDC',
      bytes('')
    );
    VariableDebtToken vdt = new VariableDebtToken();

    vdt.initialize(
      LP,
      LP_XSGD,
      IAaveIncentivesController(address(0)),
      IERC20Detailed(LP_XSGD).decimals(),
      'vdtXSGD-USDC',
      'vdtXSGD-USDC',
      bytes('')
    );

    return (a, sdt, vdt);
  }

  function _doSwap(address _senderRecipient, uint256 _swapAmt, address _tokenFrom, address _tokenTo) private {
    console2.log('Swapping..');
    int256[] memory assetDeltas = new int256[](2);

    IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](1);
    swaps[0] = IVault.BatchSwapStep({
      poolId: IFXPool(LP_XSGD).getPoolId(),
      assetInIndex: 0,
      assetOutIndex: 1,
      amount: _swapAmt,
      userData: bytes('')
    });

    IAsset[] memory assets = new IAsset[](2);
    assets[0] = IAsset(_tokenFrom);
    assets[1] = IAsset(_tokenTo);

    IVault.FundManagement memory funds = IVault.FundManagement({
      sender: _senderRecipient,
      fromInternalBalance: false,
      recipient: payable(_senderRecipient),
      toInternalBalance: false
    });
    int256[] memory limits = new int256[](2);
    limits[0] = type(int256).max;
    limits[1] = type(int256).max;

    {
      vm.startPrank(_senderRecipient);
      IERC20(_tokenFrom).approve(BALANCER_VAULT, type(uint256).max);
      int256[] memory _assetDeltas = IVault(BALANCER_VAULT).batchSwap(
        IVault.SwapKind.GIVEN_IN,
        swaps,
        assets,
        funds,
        limits,
        block.timestamp
      );
      vm.stopPrank();
      assetDeltas[0] = _assetDeltas[0];
      assetDeltas[1] = _assetDeltas[1];
    }
  }

  function _addLiquidity(bytes32 _poolId, uint256 _depositNumeraire, address _user, address _tA, address _tB) private {
    address[] memory assets = new address[](2);
    assets[0] = _tA;
    assets[1] = _tB;

    uint256[] memory maxAmountsIn = new uint256[](2);
    maxAmountsIn[0] = type(uint256).max;
    maxAmountsIn[1] = type(uint256).max;

    uint256[] memory minAmountsOut = new uint256[](2);
    minAmountsOut[0] = 0;
    minAmountsOut[1] = 0;

    address[] memory userAssets = new address[](2);
    userAssets[0] = _tA;
    userAssets[1] = _tB;
    bytes memory userDataJoin = abi.encode(_depositNumeraire, userAssets);

    IVault.JoinPoolRequest memory reqJoin = IVault.JoinPoolRequest(
      _asIAsset(assets),
      maxAmountsIn,
      userDataJoin,
      false
    );

    vm.startPrank(_user);
    IVault(BALANCER_VAULT).joinPool(_poolId, _user, _user, reqJoin);
    vm.stopPrank();
  }

  // function _removeLiquidity(
  //     bytes32 poolId,
  //     uint256 lpTokensToBurn,
  //     address user
  // )
  //     private
  //     returns (
  //         int256 vaultQuoteTokenRemoved,
  //         int256 vaultBaseTokenRemoved,
  //         uint256 poolTotalLiq,
  //         uint256[] memory poolIndividualLiq
  //     )
  // {
  //     vm.startPrank(user);

  //     address[] memory sorted = _sortAssetsList(address(_eurs), address(_usdc));

  //     bytes memory userData = abi.encode(lpTokensToBurn, sorted);

  //     IVault.ExitPoolRequest memory req = IVault.ExitPoolRequest({
  //         assets: _asIAsset(sorted),
  //         minAmountsOut: _uint256ArrVal(2, 0),
  //         userData: userData,
  //         toInternalBalance: false
  //     });

  //     vault.exitPool(poolId, user, payable(user), req);
  //     vm.stopPrank();
  // }

  // ERC20 helper functions copied from balancer-core-v2 ERC20Helpers.sol
  function _asIAsset(address[] memory addresses) internal pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      assets := addresses
    }
  }
}

// function swapInFXPool() private {}

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
  function getPoolId() external view returns (bytes32);

  function viewParameters() external view returns (uint256, uint256, uint256, uint256, uint256);

  // returns(totalLiquidityInNumeraire, individual liquidity)
  function liquidity() external view returns (uint256, uint256[] memory);

  function totalSupply() external view returns (uint256);

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);
}

interface IHLPOracle {
  function baseContract() external view returns (address);

  function quotePriceFeed() external view returns (address);
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}
