rm -rf $HOME/.bitsongd  
bitsongd init test1 

bitsongd config chain-id localnet
bitsongd config keyring-backend test
bitsongd config broadcast-mode block
rm -rf ./test-keys
mkdir ./test-keys

bitsongd keys add validator $KEYRING --output json > ./test-keys/validator_seed.json 2>&1
sleep 1
bitsongd keys add user $KEYRING --output json > ./test-keys/key_seed.json 2>&1
sleep 1
bitsongd keys add relayer $KEYRING --output json > ./test-keys/relayer_seed.json 2>&1
sleep 1

bitsongd init-from-state validator ../export-height.json  validator --old-moniker Forbole --old-account-addr bitsong166d42nyufxrh3jps5wx3egdkmvvg7jl6k33yut --voting-period 30s --overwrite --chain-id localnet

bitsongd start --x-crisis-skip-assert-invariants
