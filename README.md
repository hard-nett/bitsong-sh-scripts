# bitsong upgrade tests

This is a simple test in response to the PFM issue on the BitSong network.

## Packet forward middleware Requirements

### Install Hermes
```bash
# rustup update stable

cargo install ibc-relayer-cli --bin hermes --locked
```

### Init Hermes
```bash
./hermes-init.sh
```

### Start
```bash
# chain-1
./start.sh bitsongd test-1 ./data 26657 26656 6060 9090 ubtsg

# chain-2
./start.sh bitsongd test-2 ./data 27657 27656 7060 10090 ubtsg
```

### Stop
```bash
./stop.sh bitsongd
```

### Start Hermes
```bash
hermes start
```

## Chain Upgrade V0.17.0 -> V0.18.0 

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