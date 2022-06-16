import { ZERO_ADDRESS } from '../../helpers/constants';
import { ePolygonNetwork } from '../../helpers/types';

export const HALO_CONTRACT_ADDRESSES = {
  [ePolygonNetwork.matic]: {
    rewardToken: '0x47BE779De87de6580d0548cde80710a93c502405',
    emissionManager: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    lendingPoolAddress: '',
    rnbw: '0xe94b97b6b43639e238c851a7e693f50033efd75c',
    xrnbw: '0x47BE779De87de6580d0548cde80710a93c502405',
    curveFactory: '0xFA505d02269bF4Ea59355a4e37fBd882122717e5',
    usdc: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    usdcRnbwPair: '0x2bcfd3c474484a7b07ca616d70a36c184bbd7ef0', // sushi
    fallbackPriceOracle: '0x0000000000000000000000000000000000000000',
  },
  [ePolygonNetwork.mumbai]: {},
};
