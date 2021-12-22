import { ZERO_ADDRESS } from '../../helpers/constants';
import { eEthereumNetwork } from '../../helpers/types';

export const HALO_CONTRACT_ADDRESSES = {
  [eEthereumNetwork.buidlerevm]: {},
  [eEthereumNetwork.hardhat]: {},
  [eEthereumNetwork.coverage]: {},
  [eEthereumNetwork.kovan]: {
    rewardToken: '0xCffb28605165012cc1e334336c72143eA1a8f47d',
    emissionManager: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    lendingPoolAddress: '',
    rnbw: '0x518D2efa638c91e15b80Db646cb9A9dB5E976f84',
    xrnbw: '0xCffb28605165012cc1e334336c72143eA1a8f47d',
    curveFactory: '0x509c2a6a4F847b30f600230097bc8e50146BC757',
    usdc: '0x4B466AeAa9c5f639fE7eA5A4692e9ca34afD9CC6',
    usdcRnbwPair: '0x509c2a6a4F847b30f600230097bc8e50146BC757',
    fallbackPriceOracle: ZERO_ADDRESS,
  },
  [eEthereumNetwork.ropsten]: {},
  [eEthereumNetwork.main]: {
    rewardToken: '0x47BE779De87de6580d0548cde80710a93c502405',
    emissionManager: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    lendingPoolAddress: '',
    rnbw: '0xe94b97b6b43639e238c851a7e693f50033efd75c',
    xrnbw: '0x47BE779De87de6580d0548cde80710a93c502405',
    curveFactory: '0xFA505d02269bF4Ea59355a4e37fBd882122717e5',
    usdc: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    usdcRnbwPair: '0x2bcfd3c474484a7b07ca616d70a36c184bbd7ef0', // sushi
    fallbackPriceOracle: '0x5B09E578cfEAa23F1b11127A658855434e4F3e09',
  },
  [eEthereumNetwork.tenderly]: {},
};
