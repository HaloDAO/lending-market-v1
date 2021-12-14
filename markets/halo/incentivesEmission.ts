import { eEthereumNetwork } from '../../helpers/types';
import { parseEther } from '@ethersproject/units';

const AtokenAddresses = {
  [eEthereumNetwork.buidlerevm]: {},
  [eEthereumNetwork.hardhat]: {},
  [eEthereumNetwork.coverage]: {},
  [eEthereumNetwork.kovan]: {
    AAVE: '0x8C98CD6686F28b49D28e561d37F017bB456CD8C5',
    BUSD: '0x3d754c7607433b115337F7B0544fb23b356367b5',
    DAI: '0x0C1b4e81fC6B30ead94Cc7C0a643974183be796e',
    XSGD: '0xE2cc327F15f04fb3607F2b7291aE8AB62908Af2B',
    THKD: '0x5c9A3Fcc66a5d8095c303eDf6e5A5e7f73a8cb85',
    SUSD: '0x4AfCb5323C9B49Cc24792697D44C3b52865764F7',
    TUSD: '0xB90221C40cb0f781AdFe6De02c348435a6837a0E',
    USDC: '0xdB74bF644F5124603973aEB211D10801a9b0BF44',
    USDT: '0x2c585fF6E0C75677aB5E0C4c46404329917197fE',
    WBTC: '0xe91dcBfcA6818CfE13D397211E053460A94a250D',
    WETH: '0xCE507Bd492B840b26d314807b3beC05fe2941200',
  },
  [eEthereumNetwork.ropsten]: {},
  [eEthereumNetwork.main]: {},
  [eEthereumNetwork.tenderlyMain]: {},
};

export const HaloIncentives = {
  EmissionConfig: {
    [eEthereumNetwork.buidlerevm]: {},
    [eEthereumNetwork.hardhat]: {},
    [eEthereumNetwork.coverage]: {},
    [eEthereumNetwork.kovan]: [
      {
        emissionPerSecond: parseEther('1'),
        totalStaked: 0,
        underlyingAsset: AtokenAddresses[eEthereumNetwork.kovan].AAVE,
      },
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
    [eEthereumNetwork.tenderlyMain]: {},
  },
};
