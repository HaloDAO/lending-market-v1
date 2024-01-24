import { task } from 'hardhat/config';
import { getATokensAndRatesHelper, getLendingPoolAddressesProvider } from '../../helpers/contracts-getters-ledger';
import { getLedgerSigner } from '../../helpers/contracts-helpers';
import { haloContractAddresses } from '../../helpers/halo-contract-address-network';
import { getAssetAddress } from '../helpers/halo-helpers/util-getters';

task('halo:newasset:configure-reserve', 'Configure the reserve')
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('lp', 'If asset is an LP')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify, symbol, lp }, localBRE) => {
    await localBRE.run('set-DRE');
    const network = localBRE.network.name;

    const assetAddress = getAssetAddress(lp, network, symbol);

    console.log(`assetAddress is: ${assetAddress} and it is a ${lp ? 'LP token' : 'not a LP token'}`);

    const aTokensAndRatesHelper = await getATokensAndRatesHelper(
      haloContractAddresses(network).lendingMarket!.protocol.aTokensAndRatesHelper
    );

    const addressProvider = await getLendingPoolAddressesProvider(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
    );

    const signer = await getLedgerSigner();

    await addressProvider.setPoolAdmin(haloContractAddresses(network).lendingMarket!.protocol.aTokensAndRatesHelper);
    console.log('set pool admin done');

    // WARNING: This part is hardcoded since we are using the same strategy for all stable coins. Change if necessary
    const reserveConfig = [
      {
        asset: assetAddress,
        baseLTV: '8000',
        liquidationThreshold: '8500',
        liquidationBonus: '10500',
        reserveFactor: '1000',
        stableBorrowingEnabled: false,
        borrowingEnabled: false,
      },
    ];

    await aTokensAndRatesHelper.configureReserves(reserveConfig);
    console.log('configureReserves done');

    await addressProvider.setPoolAdmin(await signer.getAddress());
    console.log(
      `Pool Admin should be ${await signer.getAddress()}, your current pool adming is ${await addressProvider.getPoolAdmin()}`
    );
  });
