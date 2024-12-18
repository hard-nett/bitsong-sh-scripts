# V019

## TODO
- set delgations so b.slash kills val1 
- add queries to assure curernt patch delegation issue has been replicated in test env
- c.upgrade sanity
- d.confirm sanity

### Step 1: Configure nodes, keys, genesis,config, start Val1
```sh
./a.start.sh 
```
### Step 2: Start Val2, delegate to validators, kill Val1 and simulate slahing events, restart val1, confirm slashing event was registered
```sh
sh b.slash.sh 
```
### Step 3: propose vote and proceed with upgrade for both validators 
```sh
sh c.update.sh 
```
### Step 4: Confirm
```sh
sh d.confirm.sh  
```

## Step 5: Cleaning Up Test service 
Once complete testing, you may want to kill any bitsongd processes that may be running: 
```sh
pkill -f bitsongd
```

<!-- # OPTION 2: Via Exports 
To verify the v019 upgradeHandler logic it performs as expected, we can apply the same logic while exporting the app state into a genesisDoc. This lets us perform calculations on the appstate after the network is migrated, specifically ensuring the calculated rewards is not different the actual.

## A. Create `export-corrupt.json` 
Using `v0.18.1` of bitsongd:
```sh
bitsongd export > export-corrupt.json
```
## B. Compile V019-Export patch 
To simulate the upgrade, we need to use the bitsong app that has the custom export cli function implemented:
Using `v0.18.2-export` of bitsongd:
```sh
bitsongd export > export-patched.json
``` -->