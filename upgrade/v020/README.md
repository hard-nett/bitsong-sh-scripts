# V020


### Run the tests
```sh
sh a.start.sh
```

<!-- 
## Explanation 
 Slahing events not registered During `x/slashing` keeper initialization, a default app codec was passed to the slashing keeper, instead of the one registered with the rest of the applications keepers. 
Due to this error, when validators were slashed, the `BeforeValidatorSlashed` hook was not properly executed, resulting in `updateValidatorSlashFraction` not being called in the distribution module. 
This specifically is why when rewards are calculated, and all slashing events are historically iterated for a validator, the distribution module is missing any that occured post `v0.18.0` upgrade, and the result is tokens to reward calculated by shares differs than the ones calculated by tokens.


In these tests, we start with 1 validator chain on genesis, and we spin up a second validator. All delegations to validators were made by 4 wallets, each of the validators self stake, and 1 delegator to both. del1 delegates to val1 & val2, while del2 only delegates to val2 with a much greater voting power,to keep blocks producing when val1 gets slashed. 

Here we check that the amounts gone to the delegators during upgrade are consistent with the slashing events that actually occured. With v0.18, slashing events are not registered with the distribution module, causing incosistencies calculating rewards, since the staking module keeps track of the actual voting power.

In order to do so, we need to know: 
- the amount of tokens / voting power slashed for a validator
- the expected rewards to have been accumulated & claimed during upgrade

Before the upgrade, 
val1 has `100000000.000000000000000000` delegation shares, and `99000000` tokens, since we slash this validator prior to proposing the upgrade. `19341.032652559072375062` total outstanding rewards exist once val1 has been slashed. Rewards are calculated by getting the delegators shares for a 

del1 has `98.010000` Btsg, delegated to val1, with `99000000` shares. 99 btsg was originally delegated, and .99 has been slashed. 

### 
The upgrade gets proposed on block `20`, with `4550ubtsg` being minted each block. Prior to the upgrade, the balances are: -->
