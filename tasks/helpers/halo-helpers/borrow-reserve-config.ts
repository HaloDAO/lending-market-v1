import { task } from 'hardhat/config';
import { eAvalancheNetwork, eContractid, eEthereumNetwork, eNetwork, ePolygonNetwork } from '../../../helpers/types';

import {
  getHaloUiPoolDataProvider,
  getIncentivePoolDataProvider,
  getLendingPoolConfiguratorProxy,
  getPriceOracle,
  getUiPoolDataProvider,
  getWETHMocked,
} from '../../../helpers/contracts-getters';
import { parseEther } from 'ethers/lib/utils';
import { haloContractAddresses } from '../../../helpers/halo-contract-address-network';
import { getAssetAddress } from './util-getters';

task(`external:disable-borrow-reserve`, `Enable or disable borrowing in reserve`)
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('lp', 'If asset is an LP')
  .setAction(async ({ symbol, lp }, localBRE) => {
    await localBRE.run('set-DRE');
    if (!localBRE.network.config.chainId) {
      throw new Error('INVALID_CHAIN_ID');
    }

    const network = localBRE.network.name;

    const lendingPoolConfigurator = await getLendingPoolConfiguratorProxy(
      haloContractAddresses(network).lendingMarket?.protocol.lendingPoolConfigurator
    );

    await lendingPoolConfigurator.disableBorrowingOnReserve(getAssetAddress(lp, network, symbol));
    await lendingPoolConfigurator.disableReserveStableRate(getAssetAddress(lp, network, symbol));

    const oracle = await getPriceOracle('0xE911bA4d01b64830160284E42BfC9b9933fA19BA');
  });
