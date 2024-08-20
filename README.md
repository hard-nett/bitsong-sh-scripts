# bitsong-pfm-test

This is a simple test in response to the PFM issue on the BitSong network.

## Start
```bash
# chain-1
./start.sh bitsongd test-1 ./data 26657 26656 6060 9090 ubtsg

# chain-2
./start.sh bitsongd test-2 ./data 27657 27656 7060 10090 ubtsg
```

## Stop
```bash
./stop.sh bitsongd
```