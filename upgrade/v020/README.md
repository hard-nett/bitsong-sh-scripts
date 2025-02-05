# V020


### Run the tests
```sh
sh a.start.sh
```

## Explanation 
Slahing events not registered During `x/slashing` keeper creation, a default app codec was passed to the slashing keeper, instead of the one registered with the rest of the applications keepers. 
Due to this error, when validators were slashed, the `BeforeValidatorSlashed` hook, called by the staking module to the distribution modules `updateValidatorSlashFraction`, which is what saves an index of the slashing event that took place over a delegation period. This specifically is why when rewards are calculated (which are done by the distribution module in communication with the staking module), in order to calculate rewards, the distribution module iterates over the period of time between claiming rewards and the last delegation period, and since there are slashing events that do not exist, the result of the rewards that expect to have accurately included the slashing events differs from the rewards calculated by the delegators shares for that validator. Its helpful to clarify, that when a slashing event occurs, the staking module updates the total tokens the validator has delegated to them. This effectively reduces the value of each delegator share (rather than iteratively slashing the tokens of every delegation entry), and hence why we are able to accurately calculate the rewards from delegator shares, even with the error present after the v0.18 upgrade. For more info on delegator-shares, [review here](https://docs.cosmos.network/v0.47/build/modules/staking#delegator-shares).

## Test Simulation Review
In these tests, we start with 1 validator chain on genesis, and we spin up a second validator. All delegations to validators were made by 4 wallets, each of the validators self stake, and 1 delegator to both. del1 delegates to val1 & val2, while del2 only delegates to val2 with a much greater voting power,to keep blocks producing when val1 gets slashed. 

Here we check that the amounts gone to the delegators during upgrade are consistent with the slashing events that actually occured. With v0.18, slashing events are not registered with the distribution module, causing incosistencies calculating rewards, since the staking module keeps track of the actual voting power.
