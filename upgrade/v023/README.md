# v023 manual 

These scripts cover reverting back into use of the distribution keeper module for community-pool deposits.

Make sure you have the prerequisites installed for compiling go-bitsong source code before running.

## Running Tests
To run the tests:
```sh
sh a.community-pool-fix.sh
```

## Description
Here's a breakdown of the checks made in the test:

### Pre-Upgrade Checks
- **Funding Community Pool:** The test funds the community pool with a fantoken and checks that the transaction is successful.
- **Verifying Module Balances:** The test queries the balances of various module accounts (protocol pool, distribution module, and protocol pool escrow) before the upgrade.

### Upgrade and Post-Upgrade Checks
- **Performing Upgrade:** The test performs an upgrade to version v0.23.0-rc by stopping the node, installing the new version, and restarting the node.
- **Verifying Module Balances After Upgrade:** The test checks that:
The protocol pool balances are empty after the upgrade.
The distribution module has the expected fantoken balance after the upgrade.
- **Community Pool Spend Proposal:** The test submits a community pool spend proposal using the new x/distribution module and verifies that:
The proposal is successful.
The funds are transferred to the recipient's account.
- **Checking Protocol Pool Community Pool Spend:** The test attempts to fund the community pool using the protocolpool module and verifies that it errors, as expected.
- **Verifying Block Rewards:** The test checks that block rewards are being accurately transferred to the distribution module by verifying that the community pool balance increases over time.
Funding Community Pool: The test verifies that funding the community pool using the distribution module is successful.

### Overall Test Outcome
The test checks that the upgrade is successful, and the community pool patch is applied correctly. If all checks pass, the test outputs\
 `"COMMUNITY POOL PATCH APPLIED SUCCESSFULLY, ENDING TESTS"` \
 and exits cleanly. If any of the checks fail, the test exits with a non-zero status code.