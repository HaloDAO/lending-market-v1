import { task } from 'hardhat/config';
import { eAvalancheNetwork, eContractid, eEthereumNetwork, eNetwork, ePolygonNetwork } from '../../../helpers/types';

import {
  getHaloUiPoolDataProvider,
  getLendingPoolAddressesProvider,
  getLendingPoolConfiguratorProxy,
  getLendingPool,
  getPriceOracle,
  getATokensAndRatesHelper,
} from '../../../helpers/contracts-getters';
import { parseEther } from 'ethers/lib/utils';

task(`external:batch-init-new-asset-halo`, `Initialize Asset`).setAction(async ({ verify }, localBRE) => {
  await localBRE.run('set-DRE');
  if (!localBRE.network.config.chainId) {
    throw new Error('INVALID_CHAIN_ID');
  }
  const network = localBRE.network.name;

  const uiPoolDataProvider = await getHaloUiPoolDataProvider('0x6Af1ffC2F20e54CDED0549CEde1ba6269A615717');
  const lendingPoolAddressesProvider = await getLendingPoolAddressesProvider(
    '0x737a452ec095D0fd6740E0190670847841cE7F93'
  );
  const lendingPoolConfigurator = await getLendingPoolConfiguratorProxy('0x2a048cA932F0e915fec301Dcc9E87a9ECb6df1C9');
  const lendingPool = await getLendingPool('0xc336fa438c51862395b82bcCA809dB0257bCa968');
  const priceOracle = await getPriceOracle('0x2A26137812Ce58488EBc5cB372273Aa43Dc01351');
  const aTokensAndRatesHelper = await getATokensAndRatesHelper('0x1a7Ec858A6c1119BdB5a501A31F7F05b40673CD4');

  // console.log('aTokensAndRatesHelper', aTokensAndRatesHelper.address);
  // await priceOracle.getAssetPrice('0x0B7b473BbAA4cfADee68EC227C802e75823666F3')
  // console.log('lendingPoolAddressesProvider', await lendingPoolAddressesProvider.getLendingPool());
  // console.log('lendingPoolConfigurator', lendingPoolConfigurator);
  // console.log('lendingPool', lendingPool);
  // console.log('uiPoolDataProvider', uiPoolDataProvider);
  // console.log('priceOracle', await priceOracle.getAssetPrice('0x22e55B57075F99Eabaa8FBBC1C72432Cb935E324'));
  await lendingPoolConfigurator.batchInitReserve([
    {
      aTokenImpl: '0xD8707A3f05e11492b52035D80e2F2550CB0DDA2f',
      stableDebtTokenImpl: '0x14728E0997BE392Af7E35ff99191dc259d11D901',
      variableDebtTokenImpl: '0xA28ee68F5EFf86130FCCe7171a66cfc7df2F9766',
      underlyingAssetDecimals: '6',
      interestRateStrategyAddress: '0xbE62e58181ff3a1fc02A290597e6C0AA0Fb08D92',
      underlyingAsset: '0xEb06cF1cD90d75eC6d10bbdc43B555483674F6ff',
      treasury: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
      incentivesController: '0xAe8F4476073ea67c964F92E90cdEfd7C662181Dd',
      underlyingAssetName: 'HLPPHP',
      aTokenName: 'hHLPPHP',
      aTokenSymbol: 'hHLPPHP',
      variableDebtTokenName: 'variableHLPPHP',
      variableDebtTokenSymbol: 'variableHLPPHP',
      stableDebtTokenName: 'stbHLPPHP',
      stableDebtTokenSymbol: 'stbHLPPHP',
      params: '0x10',
    },
  ]);
  // 0x8eBFB2FC668a0ccCC8ADa5133c721a34060D1cDe uiPoolDataProvider.getReservesList
  // console.log(await lendingPool.getReservesList());
  // console.log(await lendingPool.getReserveData('0x1363b62C9A82007e409876A71B524bD63dDc67Dd'));
  // console.log(await lendingPool.getReserveData('0x0B7b473BbAA4cfADee68EC227C802e75823666F3'));
  console.log(await uiPoolDataProvider.getReservesData('0x737a452ec095D0fd6740E0190670847841cE7F93'));
  // console.log(await uiPoolDataProvider.getSimpleReservesData('0x8eBFB2FC668a0ccCC8ADa5133c721a34060D1cDe'));
  // console.log(await uiPoolDataProvider.getUserReservesData('0x737a452ec095D0fd6740E0190670847841cE7F93', '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd'));

  await lendingPoolAddressesProvider.setPoolAdmin('0x1a7Ec858A6c1119BdB5a501A31F7F05b40673CD4');

  const reserveConfig = [
    {
      asset: '0xEb06cF1cD90d75eC6d10bbdc43B555483674F6ff',
      baseLTV: '8000',
      liquidationThreshold: '8500',
      liquidationBonus: '10500',
      reserveFactor: '1000',
      stableBorrowingEnabled: true,
      borrowingEnabled: true,
    },
  ];

  console.log(await aTokensAndRatesHelper.configureReserves(reserveConfig));
  await lendingPoolAddressesProvider.setPoolAdmin('0x235A2ac113014F9dcb8aBA6577F20290832dDEFd');
});
