import { task } from 'hardhat/config';
import {
  deployLendingPoolAddressesProvider,
  deployLendingPoolAddressesProviderRegistry,
} from '../../helpers/contracts-deployments';
import { getEthersSigners } from '../../helpers/contracts-helpers';
import { waitForTx } from '../../helpers/misc-utils';
import { HaloConfig } from '../../markets/halo';

task('halo:dev:deploy-address-provider', 'Deploy address provider, registry and fee provider for dev enviroment')
  .addFlag('verify', 'Verify contracts at Etherscan')
  .setAction(async ({ verify }, localBRE) => {
    await localBRE.run('set-DRE');

    const admin = await (await getEthersSigners())[0].getAddress();

    /**
     * Main registry of addresses part of or connected to the protocol, including permissioned roles
     * - Acting also as factory of proxies and admin of those, so with right to change its implementations
     * - Owned by the Aave Governance
     */
    const addressesProvider = await deployLendingPoolAddressesProvider(HaloConfig.MarketId, verify);
    await waitForTx(await addressesProvider.setPoolAdmin(admin));
    await waitForTx(await addressesProvider.setEmergencyAdmin(admin));

    /**
     *  Main registry of LendingPoolAddressesProvider of multiple Aave protocol's markets
     * - Used for indexing purposes of Aave protocol's markets
     * - The id assigned to a LendingPoolAddressesProvider refers to the market it is connected with,
     *   for example with `0` for the Aave main market and `1` for the next created
     *
     */
    const addressesProviderRegistry = await deployLendingPoolAddressesProviderRegistry(verify);
    await waitForTx(await addressesProviderRegistry.registerAddressesProvider(addressesProvider.address, 1));
  });
