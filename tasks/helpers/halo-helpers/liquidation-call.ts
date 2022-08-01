import { task } from 'hardhat/config';
import { eAvalancheNetwork, eContractid, eEthereumNetwork, eNetwork, ePolygonNetwork } from '../../../helpers/types';
import BigNumber from 'bignumber.js';

import {
  getAaveProtocolDataProvider,
  getHaloUiPoolDataProvider,
  getIncentivePoolDataProvider,
  getLendingPool,
  getUiPoolDataProvider,
  getWETHMocked,
  getMintableERC20,
} from '../../../helpers/contracts-getters';
import { parseEther } from 'ethers/lib/utils';

task(`external:liquidation-call`, `Liquidation Call`).setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');
  if (!localBRE.network.config.chainId) {
    throw new Error('INVALID_CHAIN_ID');
  }
  const network = localBRE.network.name;

  const hre = require('hardhat');
  const accounts = await hre.ethers.getSigners();
  const userToLiquidate = accounts[4].address;
  const collateralAsset = '0xc1CbE9733B845d3ab7C4004B118003d5554Cf1d1';
  const debtAsset = '0x4DCE1178D2A368397c09fc6C63e2f82F00a2Ca09';

  // kovan
  const uiPoolDataProvider = await getHaloUiPoolDataProvider('0x6Af1ffC2F20e54CDED0549CEde1ba6269A615717');
  const uiProtocolDataProvider = await getAaveProtocolDataProvider('0x3d7743822dcf6477F7F6d578CaE19FA78193B8Ba');
  const lendingPool = await getLendingPool('0xc336fa438c51862395b82bcCA809dB0257bCa968');

  const userDebtData = await uiProtocolDataProvider.getUserReserveData(debtAsset, userToLiquidate);
  const amountToLiquidate = new BigNumber(userDebtData.currentVariableDebt.toString())
    // .div(2)
    .toFixed(0);

  console.log(amountToLiquidate);
  console.log(await lendingPool.getUserAccountData(userToLiquidate));

  const tx = await lendingPool.liquidationCall(
    collateralAsset, // LP-xSGD-uSDC
    debtAsset,
    userToLiquidate,
    amountToLiquidate,
    false
  );

  console.log(`Liquidation Successful ${tx.hash}`);
});
