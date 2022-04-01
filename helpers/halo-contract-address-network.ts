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
  switch (symbol.toUpperCase()) {
    case 'FXPHP':
      return haloContractAddresses(network).tokens.fxPHP!;
    case 'XSGD':
      return haloContractAddresses(network).tokens.XSGD!;
    case 'UST':
      return haloContractAddresses(network).tokens.UST!;
    case 'USDC':
      return haloContractAddresses(network).tokens.USDC!;
    case 'EURS':
      return haloContractAddresses(network).tokens.EURS!;
    case 'XIDR':
      return haloContractAddresses(network).tokens.XIDR!;
    default:
      return '';
  }
};

export const priceOracleAddress = (network: string, symbol: string) => {
  switch (symbol.toUpperCase()) {
    case 'FXPHP':
      return haloContractAddresses(network).lendingMarket!.priceOracles.fxPHP!;
    case 'XSGD':
      return haloContractAddresses(network).lendingMarket!.priceOracles.XSGD!;
    case 'UST':
      return haloContractAddresses(network).lendingMarket!.priceOracles.UST!;
    case 'HLP_PHP_USD':
      return haloContractAddresses(network).lendingMarket!.priceOracles.HLP_PHP_USD!;
    default:
      return '';
  }
};
