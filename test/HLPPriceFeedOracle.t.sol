pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import {Vm} from 'forge-std/Vm.sol';
import 'forge-std/console.sol';

import {IERC20} from '../contracts/incentives/interfaces/IERC20.sol';

import {ILendingPool} from '../contracts/interfaces/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {IAaveOracle} from '../contracts/misc/interfaces/IAaveOracle.sol';
import {AaveOracle} from '../contracts/misc/AaveOracle.sol';

import {MockAggregator} from '../contracts/mocks/oracle/CLAggregators/MockAggregator.sol';
import {IHaloUiPoolDataProvider} from '../contracts/misc/interfaces/IHaloUiPoolDataProvider.sol';

import {DataTypes} from '../contracts/protocol/libraries/types/DataTypes.sol';
import {IAToken} from '../contracts/interfaces/IAToken.sol';

interface IOracle {
  function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

  function latestAnswer() external view returns (int256);
}

contract HLPPriceFeedOracle is Test {
  address constant LENDINPOOL_PROXY_ADDRESS = 0xC73b2c6ab14F25e1EAd3DE75b4F6879DEde3968E;
  address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant XSGD = 0x70e8dE73cE538DA2bEEd35d14187F6959a8ecA96;
  address constant XSGD_MINTER = 0x8c3b0cAeC968b2e640D96Ff0B4c929D233B25982;
  string private RPC_URL = vm.envString('MAINNET_RPC_URL');
  uint256 constant FORK_BLOCK = 15432282;
  address constant ORACLE_OWNER = 0x21f73D42Eb58Ba49dDB685dc29D3bF5c0f0373CA;
  address constant ETH_USD_CHAINLINK = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
  address constant USDC_USD_CHAINLINK = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
  address constant HLP_XSGD = 0x64DCbDeb83e39f152B7Faf83E5E5673faCA0D42A;
  address constant HLP_XSGD_ORACLE = 0xE911bA4d01b64830160284E42BfC9b9933fA19BA;
  address constant AAVE_ORACLE = 0x50FDeD029612F6417e9c9Cb9a42848EEc772b9cC;
  address constant UI_DATA_PROVIDER = 0x6c00EC488A2D2EB06b2Ed28e1F9f12C38fBCF426;
  address constant LENDINGPOOL_ADDRESS_PROVIDER = 0xD8708572AfaDccE523a8B8883a9b882a79cbC6f2;
  address constant LP_USER = 0x01e198818a895f01562E0A087595E5b1C7bb8d5c;
  address constant XSGD_HOLDER = 0x90f25dc48580503c6cE7735869965C4bc491797b;

  bytes32 constant POOL_ID_XSGD_USDC = 0x55bec22f8f6c69137ceaf284d9b441db1b9bfedc0002000000000000000003cd;

  address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
  ILendingPool constant LP = ILendingPool(LENDINPOOL_PROXY_ADDRESS);
  address me = address(this);

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);

    vm.prank(XSGD_HOLDER);
    IERC20(XSGD).transfer(me, 5_000_000 * 1e6);

    vm.prank(0xE982615d461DD5cD06575BbeA87624fda4e3de17); // usdc masterMinter
    IFiatToken(USDC).configureMinter(me, 2_000_000_000_000 * 1e6);
    // mint usdc tokens to us
    IFiatToken(USDC).mint(me, 2_000_000_000_000 * 1e6);
  }

  function testPriceManipulation() public {
    // output:
    //     ratio of tokens
    //     liquidity
    //     price of XSGD/USDC LP token according to HLPOracle
    // swap XSGD for USDC
    // output: price of XSGD/USDC LP token according to HLPOracle
    int256 lpEthPrice = IOracle(HLP_XSGD_ORACLE).latestAnswer();
    console.log('lpEthPrice', uint256(lpEthPrice));

    _doSwap(me, 50_000 * 1e6, XSGD, USDC);
  }

  function _doSwap(address _senderRecipient, uint256 _swapAmt, address _tokenFrom, address _tokenTo) private {
    int256[] memory assetDeltas = new int256[](2);
    IVault vault = IVault(BALANCER_VAULT);

    IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](1);
    swaps[0] = IVault.BatchSwapStep({
      poolId: POOL_ID_XSGD_USDC,
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
      int256[] memory _assetDeltas = vault.batchSwap(
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
}

// function swapInFXPool() private {}

interface IFiatToken {
  function mint(address to, uint256 amount) external;

  function configureMinter(address minter, uint256 minterAllowedAmount) external;

  function masterMinter() external view returns (address);

  function increaseMinterAllowance(address _minter, uint256 _increasedAmount) external view;
}

interface IVault {
  enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
  }

  /**
   * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
   * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
   *
   * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
   * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
   * the same index in the `assets` array.
   *
   * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
   * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
   * `amountOut` depending on the swap kind.
   *
   * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
   * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
   * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
   *
   * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
   * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
   * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
   * or unwrapped from WETH by the Vault.
   *
   * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
   * the minimum or maximum amount of each token the vault is allowed to transfer.
   *
   * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
   * equivalent `swap` call.
   *
   * Emits `Swap` events.
   */
  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  /**
   * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
   * `assets` array passed to that function, and ETH assets are converted to WETH.
   *
   * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
   * from the previous swap, depending on the swap kind.
   *
   * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
   * used to extend swap behavior.
   */
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

  /**
   * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
   * `recipient` account.
   *
   * If the caller is not `sender`, it must be an authorized relayer for them.
   *
   * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
   * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
   * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
   * `joinPool`.
   *
   * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
   * transferred. This matches the behavior of `exitPool`.
   *
   * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
   * revert.
   */
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
