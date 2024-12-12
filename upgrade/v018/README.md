# V018

### Step 1
```sh
sh a.start-for-upgrade.sh
```
### Step 2: Submit upgrade
```sh
# run this as soon as the first blocks are printed in a new terminal
sh b.upgrade.sh
```
### Step 3: Proceed With Upgrade
```sh
# run this once upgrade height is reached
sh c.post-upgrade.sh
```

## Init-From-State 

### Step 1: Start network from state export located in `../export-height.json`
```sh
sh o.init-from-state.sh
```

### Step 2: Submit upgrade
```sh
# run this as soon as the first blocks are printed in a new terminal
sh b.upgrade.sh
```

### Step 3: Proceed With Upgrade
```sh
# run this once upgrade height is reached
sh c.post-upgrade.sh
```