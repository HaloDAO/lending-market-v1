import { task } from 'hardhat/config';
import {
  getATokensAndRatesHelper,
  getFirstSigner,
  getLendingPoolAddressesProvider,
} from '../../helpers/contracts-getters';
import { haloContractAddresses } from '../../helpers/halo-contract-address-network';
import { getAssetAddress } from '../helpers/halo-helpers/util-getters';

task('halo:newasset:configure-reserve', 'Configure the reserve')
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('lp', 'If asset is an LP')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify, symbol, lp }, localBRE) => {
    const network = localBRE.network.name;

    // const assetAddress = getAssetAddress(lp, network, symbol);
    const assetAddress = '0x9649201B51de91E059076329531347a9e615ABC8';

    console.log(`assetAddress is: ${assetAddress} and it is a ${lp ? 'LP token' : 'not a LP token'}`);

    const aTokensAndRatesHelper = await getATokensAndRatesHelper('0xde29585a4134752632a07f09BCA0f02F72a33B8d');

    const addressProvider = await getLendingPoolAddressesProvider('0x59847B1314E1A1cad9E0a207F6E53c04F4FAbFBD');

    const signer = await localBRE.ethers.getSigners();

    await addressProvider.setPoolAdmin('0xde29585a4134752632a07f09BCA0f02F72a33B8d');

    // WARNING: This part is hardcoded since we are using the same strategy for all stable coins. Change if necessary
    const reserveConfig = [
      {
        asset: assetAddress,
        baseLTV: '7000',
        liquidationThreshold: '7500',
        liquidationBonus: '11000',
        reserveFactor: '2000',
        stableBorrowingEnabled: true,
        borrowingEnabled: true,
      },
    ];

    await aTokensAndRatesHelper.configureReserves(reserveConfig);
    await addressProvider.setPoolAdmin(await signer[0].getAddress());
    console.log(
      `Pool Admin should be ${await signer[0].getAddress()}, your current pool adming is ${await addressProvider.getPoolAdmin()}`
    );
  });
