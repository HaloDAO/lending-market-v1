import { task } from 'hardhat/config';
import { loadPoolConfig, ConfigNames, getWrappedNativeTokenAddress } from '../../helpers/configuration';
import { deployWETHGateway } from '../../helpers/contracts-deployments';
import { printContracts } from '../../helpers/misc-utils';

const CONTRACT_NAME = 'WETHGateway';

task(`halo:mainnet-4`, `Deploys the ${CONTRACT_NAME} contract`)
  .addParam('pool', `Pool name to retrieve configuration, supported: ${Object.values(ConfigNames)}`)
  .addFlag('verify', `Verify ${CONTRACT_NAME} contract via Etherscan API.`)
  .setAction(async ({ verify, pool }, localBRE) => {
    await localBRE.run('set-DRE');
    const poolConfig = loadPoolConfig(pool);
    const Weth = await getWrappedNativeTokenAddress(poolConfig);

    const wethGateWay = await deployWETHGateway([Weth], verify);

    console.log(`${CONTRACT_NAME}.address`, wethGateWay.address);
    console.log(`\tFinished ${CONTRACT_NAME} deployment. Change the weth gateway in markets now.`);
  });
