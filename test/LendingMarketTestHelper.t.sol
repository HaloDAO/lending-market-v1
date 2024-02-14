pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';

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
import {
  DefaultReserveInterestRateStrategy
} from '../contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {ILendingPoolConfigurator} from '../contracts/interfaces/ILendingPoolConfigurator.sol';
import {LendingPoolConfigurator} from '../contracts/protocol/lendingpool/LendingPoolConfigurator.sol';

import {FXEthPriceFeedOracle, FXPool, AggregatorV3Interface} from '../contracts/xave-oracles/FXEthPriceFeedOracle.sol';
import '../contracts/xave-oracles/libraries/ABDKMath64x64.sol';

contract LendingMarketTestHelper is Test {
  using ABDKMath64x64 for int128;
  using ABDKMath64x64 for int256;
  using ABDKMath64x64 for uint256;

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

  function _deployReserve() internal {
    (AToken at, StableDebtToken sdt, VariableDebtToken vdt) = _deployAaveTokens();
    DefaultReserveInterestRateStrategy dris = _deployDefaultReserveInterestStrategy();

    LendingPoolConfigurator lpc =
      LendingPoolConfigurator(ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESS_PROVIDER).getLendingPoolConfigurator());

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

  function _deployAndSetLPOracle(address baseAssim, address quoteAssim) internal returns (address) {
    FXEthPriceFeedOracle lpOracle =
      new FXEthPriceFeedOracle(
        FXPool(LP_XSGD),
        AggregatorV3Interface(ETH_USD_ORACLE),
        'LPXSGD-USDC/ETH',
        BALANCER_VAULT,
        baseAssim,
        quoteAssim
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

    console2.log('Aave Oracle price', _price);

    return address(lpOracle);
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

  function _deployAaveTokens()
    private
    returns (
      AToken,
      StableDebtToken,
      VariableDebtToken
    )
  {
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

  function _swapAndCheck(
    address lpOracle,
    uint256 amountToSwap,
    address swapIn,
    address swapOut,
    string memory swapLabel,
    bool withLogs,
    address user
  ) internal {
    int256 lpEthPrice0 = IOracle(lpOracle).latestAnswer();
    uint256 fees0 = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();

    (uint256 totalLiquidityInNumeraire0, uint256[] memory individualLiquidity0) = IFXPool(LP_XSGD).liquidity();
    if (withLogs) {
      console2.log('[%s] lpEthPrice0\t', swapLabel, uint256(lpEthPrice0));
      console2.log('[%s] fees0\t', swapLabel, fees0);
      console2.log('[%s] totalLiquidityInNumeraire0\t', swapLabel, totalLiquidityInNumeraire0);
      console2.log(
        '[%s] individualLiquidity0',
        swapLabel,
        individualLiquidity0[0] / 1e18,
        individualLiquidity0[1] / 1e18
      );
    }

    _doSwap(user, amountToSwap, swapIn, swapOut);

    (uint256 totalLiquidityInNumeraire1, ) = IFXPool(LP_XSGD).liquidity();

    if (totalLiquidityInNumeraire0 < totalLiquidityInNumeraire1) {
      if (withLogs) {
        console2.log(
          '[%s] totalLiquidityInNumeraire ADDED\t',
          swapLabel,
          (totalLiquidityInNumeraire1 - totalLiquidityInNumeraire0) / 1e18
        );
      }
    } else {
      if (withLogs) {
        // console2.log(
        //   '[%s] totalLiquidityInNumeraire SUBTRACTED\t',
        //   swapLabel,
        //   (totalLiquidityInNumeraire0 - totalLiquidityInNumeraire1) / 1e18
        // );
      }
    }

    int256 lpEthPrice1 = IOracle(lpOracle).latestAnswer();
    if (withLogs) {
      console2.log('[%s] lpEthPrice1\t', swapLabel, uint256(lpEthPrice1));
      console2.log('[%s] fees ADDED\t', swapLabel, IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire() - fees0);
    }

    (uint256 totalLiquidityInNumeraire2, ) = IFXPool(LP_XSGD).liquidity();

    if (totalLiquidityInNumeraire1 < totalLiquidityInNumeraire2) {
      console2.log(
        '[%s] totalLiquidityInNumeraire ADDED\t',
        swapLabel,
        (totalLiquidityInNumeraire2 - totalLiquidityInNumeraire1) / 1e18
      );
    } else {
      // console2.log(
      //   '[%s] totalLiquidityInNumeraire SUBTRACTED\t',
      //   swapLabel,
      //   (totalLiquidityInNumeraire1 - totalLiquidityInNumeraire2) / 1e18
      // );
    }

    uint256 fees1 = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();
    int256 lpEthPrice2 = IOracle(lpOracle).latestAnswer();
    // console2.log('[%s] lpEthPrice2\t', swapLabel, uint256(lpEthPrice2));
    // console2.log('[%s] fees ADDED\t', swapLabel, IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire() - fees1);

    // console2.log(swapLabel);
    // console2.log('After fee minting: lpEthPrice2 - lpEthPrice1', lpEthPrice2 - lpEthPrice1);
    // console2.log('After swap: lpEthPrice1 - lpEthPrice0', lpEthPrice1 - lpEthPrice0);
  }

  function _loopSwaps(
    uint256 times,
    uint256 amount,
    address lpOracle,
    bool withLogs,
    address user
  ) internal {
    uint256 initial = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();

    int256 beforeLoop = IOracle(lpOracle).latestAnswer();
    for (uint256 j = 0; j < times; j++) {
      if (withLogs) {
        console2.log('LOOP #', j);
      }

      _swapAndCheck(lpOracle, amount * 1e6, USDC, XSGD, '[SWAP]', withLogs, user);
      _swapAndCheck(lpOracle, amount * 1e6, XSGD, USDC, '[SWAP]', withLogs, user);
      if (withLogs) {
        console2.log('after swap: ', IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire());
        console2.log('intiial unclaimed fees: ', initial);
        console2.log('intiial oracle price: ', beforeLoop);
      }
    }
  }

  function _convertToRawAmount(uint256 amount, address assimilator) internal returns (uint256) {
    return IAssimilator(assimilator).viewRawAmount(ABDKMath64x64.fromUInt(amount));
  }

  function _convertToNumeraire(uint256 amount, address assimilator) internal returns (uint256) {
    return IAssimilator(assimilator).viewNumeraireAmount(amount).mulu(1e18);
  }

  function _loopSwapsExact(
    uint256 times,
    uint256 amount,
    address lpOracle,
    bool withLogs,
    address user
  ) internal {
    uint256 initial = IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire();

    uint256 xsgdInRawAmount = _convertToRawAmount(amount, 0xC933a270B922acBd72ef997614Ec46911747b799);

    console.log(xsgdInRawAmount);
    int256 beforeLoop = IOracle(lpOracle).latestAnswer();
    for (uint256 j = 0; j < times; j++) {
      console2.log('LOOP #', j);

      _swapAndCheck(lpOracle, amount * 1e6, USDC, XSGD, '[SWAP]', withLogs, user);
      _swapAndCheck(lpOracle, xsgdInRawAmount, XSGD, USDC, '[SWAP]', withLogs, user);
      if (withLogs) {
        console2.log('after swap: ', IFXPool(LP_XSGD).totalUnclaimedFeesInNumeraire());
        console2.log('intiial unclaimed fees: ', initial);
        console2.log('intiial oracle price: ', beforeLoop);
      }
    }
  }

  function _doSwap(
    address _senderRecipient,
    uint256 _swapAmt,
    address _tokenFrom,
    address _tokenTo
  ) internal {
    // console2.log('Swapping..');
    int256[] memory assetDeltas = new int256[](2);

    IERC20(_tokenFrom).approve(_senderRecipient, type(uint256).max);

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

    IVault.FundManagement memory funds =
      IVault.FundManagement({
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
      int256[] memory _assetDeltas =
        IVault(BALANCER_VAULT).batchSwap(IVault.SwapKind.GIVEN_IN, swaps, assets, funds, limits, block.timestamp);
      vm.stopPrank();
      assetDeltas[0] = _assetDeltas[0];
      assetDeltas[1] = _assetDeltas[1];
    }
  }

  function _addLiquidity(
    bytes32 _poolId,
    uint256 _depositNumeraire,
    address _user,
    address _tA,
    address _tB
  ) internal {
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

    IVault.JoinPoolRequest memory reqJoin =
      IVault.JoinPoolRequest(_asIAsset(assets), maxAmountsIn, userDataJoin, false);

    vm.startPrank(_user);
    IVault(BALANCER_VAULT).joinPool(_poolId, _user, _user, reqJoin);
    vm.stopPrank();
  }

  function _removeLiquidity(
    bytes32 poolId,
    uint256 lpTokensToBurn,
    address user,
    address _tA,
    address _tB
  )
    internal
    returns (
      int256 vaultQuoteTokenRemoved,
      int256 vaultBaseTokenRemoved,
      uint256 poolTotalLiq,
      uint256[] memory poolIndividualLiq
    )
  {
    vm.startPrank(user);

    address[] memory sorted = _sortAssetsList(address(_tA), address(_tB));

    bytes memory userData = abi.encode(lpTokensToBurn, sorted);

    IVault.ExitPoolRequest memory req =
      IVault.ExitPoolRequest({
        assets: _asIAsset(sorted),
        minAmountsOut: _uint256ArrVal(2, 0),
        userData: userData,
        toInternalBalance: false
      });

    IVault(BALANCER_VAULT).exitPool(poolId, user, payable(user), req);
    vm.stopPrank();
  }

  function _getPoolTokenRatio(bytes32 poolId) internal view returns (uint256 tokenARatio, uint256 tokenBRatio) {
    (address[] memory tokens, uint256[] memory balances, ) = IVault(BALANCER_VAULT).getPoolTokens(poolId);

    uint256 balanceTokenA = balances[0];
    uint256 balanceTokenB = balances[1];

    uint256 totalBalance = balanceTokenA + balanceTokenB;

    uint256 tokenAPercentage = (balanceTokenA * 10000) / totalBalance;
    uint256 tokenBPercentage = (balanceTokenB * 10000) / totalBalance;

    return (tokenAPercentage, tokenBPercentage);
  }

  function _asIAsset(address[] memory addresses) internal pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      assets := addresses
    }
  }

  function _uint256ArrVal(uint256 arrSize, uint256 _val) internal pure returns (uint256[] memory) {
    uint256[] memory arr = new uint256[](arrSize);
    for (uint256 i = 0; i < arrSize; i++) {
      arr[i] = _val;
    }
    return arr;
  }

  function _sortAssets(address _t0, address _t1) internal pure returns (address, address) {
    return _t0 < _t1 ? (_t0, _t1) : (_t1, _t0);
  }

  function _sortAssetsList(address _t0, address _t1) private pure returns (address[] memory) {
    (address t0, address t1) = _sortAssets(_t0, _t1);
    address[] memory sortedTokens = new address[](2);
    sortedTokens[0] = t0;
    sortedTokens[1] = t1;

    return sortedTokens;
  }
}

interface IFiatToken {
  function mint(address to, uint256 amount) external;

  function configureMinter(address minter, uint256 minterAllowedAmount) external;

  function masterMinter() external view returns (address);

  function increaseMinterAllowance(address _minter, uint256 _increasedAmount) external view;
}

interface IVault {
  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external payable;

  struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function exitPool(
    bytes32 poolId,
    address sender,
    address payable recipient,
    ExitPoolRequest memory request
  ) external;

  struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  enum SwapKind {GIVEN_IN, GIVEN_OUT}

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

  function getPoolTokens(bytes32 poolId)
    external
    view
    returns (
      address[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
    );
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

  function viewParameters()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  // returns(totalLiquidityInNumeraire, individual liquidity)
  function liquidity() external view returns (uint256, uint256[] memory);

  function totalSupply() external view returns (uint256);

  function totalUnclaimedFeesInNumeraire() external view returns (uint256);
}

interface IOracle {
  function latestRoundData()
    external
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    );

  function latestAnswer() external view returns (int256);
}

interface IERC20Detailed {
  function decimals() external view returns (uint8);
}

interface IAssimilator {
  function getRate() external view returns (uint256);

  function viewRawAmount(int128) external view returns (uint256);

  function viewNumeraireAmount(uint256) external view returns (int128);
}
