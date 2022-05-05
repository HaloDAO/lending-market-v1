import { mainnet, kovan, matic } from '@halodao/halodao-contract-addresses';

export const haloContractAddresses = (network: string) => {
  switch (network) {
    case 'main':
      return mainnet;
    case 'kovan':
      return kovan;
    case 'matic':
      return matic;
    case 'hardhat':
      return mainnet;
    default:
      return kovan;
  }
};
