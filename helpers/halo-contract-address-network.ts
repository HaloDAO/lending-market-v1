import { mainnet, kovan, matic } from '@halodao/halodao-contract-addresses';

export const haloContractAddresses = (network: string) => {
  switch (network) {
    case 'main':
      return mainnet;
    case 'kovan':
      return kovan;
    case 'matic':
      return matic;
    default:
      return kovan;
  }
};

export const underlyingAssetAddress = (network: string, symbol: string) => {
  //@todo: add curve support
  const tokens = haloContractAddresses(network).tokens;
  const lpAssets = haloContractAddresses(network).lendingMarket?.lpAssets!;
  return symbol.toLowerCase() === 'fxphp'
    ? tokens.fxPHP
    : tokens[symbol.toUpperCase()]
    ? tokens[symbol.toUpperCase()]
    : lpAssets[symbol.toUpperCase()] ?? '';
};

export const priceOracleAddress = (network: string, symbol: string) => {
  const priceOracles = haloContractAddresses(network).lendingMarket!.priceOracles;
  console.log(priceOracles);
  return symbol.toLowerCase() === 'xrnbw' ? priceOracles.xRNBW : priceOracles[symbol.toUpperCase()] ?? '';
};
