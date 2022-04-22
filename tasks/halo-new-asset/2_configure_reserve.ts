import { task } from 'hardhat/config';
import {
  getATokensAndRatesHelper,
  getFirstSigner,
  getLendingPoolAddressesProvider,
} from '../../helpers/contracts-getters';
import { haloContractAddresses } from '../../helpers/halo-contract-address-network';

task('halo:newasset:configure-reserve', 'Initialize reserve')
  .addParam('symbol', `Asset symbol, needs to have configuration ready`)
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify, symbol }, localBRE) => {
    const network = localBRE.network.name;

    const aTokensAndRatesHelper = await getATokensAndRatesHelper(
      haloContractAddresses(network).lendingMarket!.protocol.aTokensAndRatesHelper
    );

    const addressProvider = await getLendingPoolAddressesProvider(
      haloContractAddresses(network).lendingMarket!.protocol.lendingPoolAddressesProvider
    );

    const signer = await getFirstSigner();
    await addressProvider.setPoolAdmin(haloContractAddresses(network).lendingMarket!.protocol.aTokensAndRatesHelper);

    // WARNING: This part is hardcoded since we are using the same strategy for all stable coins. Change if necessary
    const reserveConfig = [
      {
        asset: haloContractAddresses(network).tokens[symbol],
        baseLTV: '8000',
        liquidationThreshold: '8500',
        liquidationBonus: '10500',
        reserveFactor: '1000',
        stableBorrowingEnabled: true,
        borrowingEnabled: true,
      },
    ];

    await aTokensAndRatesHelper.configureReserves(reserveConfig);
    await addressProvider.setPoolAdmin(await signer.getAddress());
    console.log(
      `Pool Admin should be ${await signer.getAddress()}, your current pool adming is ${await addressProvider.getPoolAdmin()}`
    );
  });
