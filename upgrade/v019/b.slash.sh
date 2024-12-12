VAL1=$(jq -r '.name' ./test-keys/validator_seed.json)
VAL1ADDR=$(jq -r '.address' ./test-keys/validator_seed.json)
VAL2=$(jq -r '.name' ./test-keys/validator_seed.json)
VAL2ADDR=$(jq -r '.address' ./test-keys/validator_seed.json)
# get val addr from genesis?
VAL1_OP_ADDR=""

DEL1=$(jq -r '.name' ./test-keys/relayer_seed.json)
DEL1ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)

DEL2=$(jq -r '.name' ./test-keys/relayer_seed.json)
DEL2ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)



export CHAIN_ID=sub-2
export DAEMON_NAME=bitsongd
export DAEMON_HOME=$HOME/.bitsongd

$DAEMON_NAME config keyring-backend test
# create delegation to both validators
$DAEMON_NAME tx staking delegate $VAL1_OP_ADDR  100000000ubtsg --from $DEL1 --gas auto --gas-adjustment 1.2 --chain-id $CHAIN_ID -y
$DAEMON_NAME tx staking delegate $VAL2_OP_ADDR  3000000000ubtsg --from $DEL2 --gas auto --gas-adjustment 1.2 --chain-id $CHAIN_ID -y
sleep 6

# delegate from slashed del to non slashed val
$DAEMON_NAME tx staking delegate $VAL2_OP_ADDR  100000000ubtsg --from $DEL1 --gas auto --gas-adjustment 1.2 --chain-id $CHAIN_ID -y


# stop bitsongd process for 1 block 
pkill -f bitsongd
sleep 6

# restart  
$DAEMON_NAME start
# confirm error exists with reward query



