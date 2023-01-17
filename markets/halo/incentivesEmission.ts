import { eEthereumNetwork } from '../../helpers/types';
import { parseEther } from '@ethersproject/units';

const AtokenAddresses = {
  [eEthereumNetwork.buidlerevm]: {},
  [eEthereumNetwork.hardhat]: {},
  [eEthereumNetwork.coverage]: {},
  [eEthereumNetwork.goerli]: {}, // Update after deployment and adding RET to lending market
  [eEthereumNetwork.kovan]: {
    // AAVE: '0x8C98CD6686F28b49D28e561d37F017bB456CD8C5',
    BUSD: '0x15e778863C9357022Edb885C2A4e42c8B7974f9F',
    DAI: '0xb4f9c51360022a23d496Fbe91eAA52929d5463e9',
    XSGD: '0x99be0614f887024b8c7b992e817BCfEF214e8C07',
    THKD: '0xF587BE7B3866aB735839ae674f0770ED1f1529e0',
    SUSD: '0xa74Ce0204584dAAACa2a8468a9f5Ae54CE063D61',
    TUSD: '0x99ED2d763c77e268642A6485f47a1b75e2C8b586',
    USDC: '0x1A020f509522A715C78a8eDdE685a78888c07476',
    USDT: '0x175854D0afEA442833472417a0EF4f7a1998F0CA',
    WBTC: '0x57253148D9B2dBaA26B9B361dd5D8719DF809f5B',
    WETH: '0x60F9e3051aBd464CA9CE0Fc8D9d99a6FDA8A1df0',
  },
  [eEthereumNetwork.ropsten]: {},
  [eEthereumNetwork.main]: {},
  [eEthereumNetwork.tenderly]: {},
};

export const HaloIncentives = {
  EmissionConfig: {
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.goerli]: {},
    [eEthereumNetwork.kovan]: [
      {
        emissionPerSecond: parseEther('2.2'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].BUSD,
      },
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].DAI,
      },
      {
        emissionPerSecond: parseEther('2.2'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].XSGD,
      },
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].THKD,
      },
      {
        emissionPerSecond: parseEther('2.2'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].SUSD,
      },
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].TUSD,
      },
      {
        emissionPerSecond: parseEther('2.2'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].USDC,
      },
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].USDT,
      },
      {
        emissionPerSecond: parseEther('2.2'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].WBTC,
      },
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].WETH,
      },
    ],
    [eEthereumNetwork.ropsten]: {},
    [eEthereumNetwork.main]: {},
    [eEthereumNetwork.tenderly]: {},
  },
};
