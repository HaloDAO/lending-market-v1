import { ZERO_ADDRESS } from '../../helpers/constants';
import { eEthereumNetwork, eArbitrumNetwork } from '../../helpers/types';

export const HALO_CONTRACT_ADDRESSES = {
  [eEthereumNetwork.buidlerevm]: {},
  [eEthereumNetwork.hardhat]: {},
  [eEthereumNetwork.coverage]: {},
  [eEthereumNetwork.kovan]: {},
  [eEthereumNetwork.ropsten]: {},
  [eEthereumNetwork.main]: {},
  [eEthereumNetwork.tenderly]: {},
  [eArbitrumNetwork.arbitrum]: {
    rewardToken: '0x323C11843DEaEa9f13126FE33B86f6C5086DE138',
    emissionManager: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    lendingPoolAddress: '',
    rnbw: '0xA4b7999A1456A481FB0F2fa7E431b9B641A00770',
    xrnbw: '0x323C11843DEaEa9f13126FE33B86f6C5086DE138',
    curveFactory: '0x972127aFf8e6464e50eFc0a2aD344063355AE424',
    usdc: '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8',
    usdcRnbwPair: '', // sushi
    fallbackPriceOracle: '0x0000000000000000000000000000000000000000', // Aave's fallbackOracle in Arbitrum is 0x0 (zero address)
  },
  [eArbitrumNetwork.arbitrumRinkeby]: {
    rewardToken: '0xfbBf11Ae3E8A4b6D9C866B3f16741D1641ccc4d5',
    emissionManager: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd',
    lendingPoolAddress: '0x0c759cb646Ae6005A554c0755F893c19D025151C',
    rnbw: '0xfbBf11Ae3E8A4b6D9C866B3f16741D1641ccc4d5',
    xrnbw: '0xAe0429F26ed25c8Ad22D2582315Cc99aa5de8fF6',
    curveFactory: '0xFf3807e87238A8dC507851Ef340D4F17dea58c88',
    usdc: '0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838',
    usdcRnbwPair: '0x235A2ac113014F9dcb8aBA6577F20290832dDEFd', // sushi
    fallbackPriceOracle: '0x6eFd3CCf5c673bd5A7Ea91b414d0307a5bAb9cC1',
  }
};

