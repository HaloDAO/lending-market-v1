import { task } from 'hardhat/config';
import { loadPoolConfig, ConfigNames, getWrappedNativeTokenAddress } from '../../helpers/configuration';
import { deployWETHGateway } from '../../helpers/contracts-deployments';

const CONTRACT_NAME = 'WETHGateway';

task(`halo:mainnet-wethgateway-4`, `Deploys the ${CONTRACT_NAME} contract`)
  .addFlag('verify', `Verify ${CONTRACT_NAME} contract via Etherscan API.`)
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');
    const poolConfig = loadPoolConfig(ConfigNames.Halo);
    const Weth = await getWrappedNativeTokenAddress(poolConfig);

    const wethGateWay = await deployWETHGateway([Weth], verify);

    console.log(`${CONTRACT_NAME}.address`, wethGateWay.address);
    console.log(`\tFinished ${CONTRACT_NAME} deployment. Change the weth gateway in markets now.`);
  });
