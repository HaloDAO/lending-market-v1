pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';

import {ILendingPool} from '../contracts/interfaces/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from '../contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {OpsConfigHelper, IOpsTestData} from './helpers/OpsConfigHelper.sol';

contract LendingMarketOpsTestAdmin is Test, OpsConfigHelper {
  //// network dependent config
  //// only the following lines are needed to be changed for different networks
  string private NETWORK = 'polygon';
  string private RPC_URL = vm.envString('POLYGON_RPC_URL');
  uint256 constant FORK_BLOCK = 52764552;
  address constant LENDINPOOL_PROXY_ADDRESS = 0x78a5B2B028Fa6Fb0862b0961EB5131C95273763B;

  //// network dependent config end

  function setUp() public {
    vm.createSelectFork(RPC_URL, FORK_BLOCK);
  }

  function testTableData() public {
    ILendingPool lendingPool = ILendingPool(LENDINPOOL_PROXY_ADDRESS);
    ILendingPoolAddressesProvider lpAddrProvider = ILendingPoolAddressesProvider(lendingPool.getAddressesProvider());
    IOpsTestData.Root memory root = _readTestData(string(abi.encodePacked('ops_admin.', NETWORK, '.json')));
    assertEq(root.lendingPool.admin, lpAddrProvider.getPoolAdmin(), 'correct pool admin set');
  }
}
