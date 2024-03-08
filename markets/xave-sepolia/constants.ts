import { ZERO_ADDRESS } from '../../helpers/constants';
import { eAvalancheNetwork } from '../../helpers/types';

export const HALO_CONTRACT_ADDRESSES = {
  [eAvalancheNetwork.avalanche]: {
    rewardToken: '',
    emissionManager: '',
    lendingPoolAddress: '',
    curveFactory: '',
    fallbackPriceOracle: ZERO_ADDRESS,
    treasury: '', // Ops Multi sig 1
  },
};
