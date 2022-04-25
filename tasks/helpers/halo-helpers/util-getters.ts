import { haloContractAddresses } from '../../../helpers/halo-contract-address-network';

export const getAssetAddress = (lp: boolean, network: string, symbol: string): string => {
  if (lp) {
    if (haloContractAddresses(network).lendingMarket!.lpAssets[symbol] === undefined)
      console.log('Asset is not an LP!');
    return haloContractAddresses(network).lendingMarket!.lpAssets[symbol];
  } else {
    return haloContractAddresses(network).tokens![symbol];
  }
};
