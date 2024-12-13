DAEMON_NAME=$1
CHAINID=$2
CHAINDIR=$3

VAL1HOME=$CHAINDIR/$CHAINID/val1
VAL2HOME=$CHAINDIR/$CHAINID/val2


DEL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
DEL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
VAL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL1ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)
VAL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)


# Define the new ports for val1
VAL1_API_PORT=1317
VAL1_GRPC_PORT=9090
VAL1_GRPC_WEB_PORT=9091
VAL1_PROXY_APP_PORT=26658
VAL1_RPC_PORT=$RPCPORT
VAL1_PPROF_PORT=6060
VAL1_P2P_PORT=26656

# Define the new ports for val2
VAL2_API_PORT=1318
VAL2_GRPC_PORT=9393
VAL2_GRPC_WEB_PORT=9394
VAL2_PROXY_APP_PORT=9395
VAL2_RPC_PORT=26958
VAL2_PPROF_PORT=6361
VAL2_P2P_PORT=26357


# start the second validator
VAL1_P2P_ADDR=$($DAEMON_NAME tendermint show-node-id --home $VAL1HOME)@localhost:$VAL1_P2P_PORT


## get current process for bitsongd 
# start validator and grab process id of bitsongd
VAL1_PID=$(pgrep -f bitsongd)
echo "VAL1_PID: $VAL1_PID"
bitsongd start --home $VAL2HOME &
VAL2_PID=$!
echo "VAL2_PID: $VAL2_PID"

# let val catch up
sleep 3

VAL1_OP_ADDR=$($DAEMON_NAME q staking validators --home $VAL1HOME -o json | jq -r '.validators[0].operator_address')
echo "VAL1_OP_ADDR: $VAL1_OP_ADDR"


# get val addr from genesis?
bitsongd tx staking create-validator \
    --amount=100000000ubtsg \
    --pubkey=$($DAEMON_NAME tendermint show-validator --home $VAL2HOME ) \
    --moniker="VAL2" \
    --chain-id=$CHAINID \
    --home $VAL2HOME \
    --from=$VAL2 \
    --commission-rate="0.10" \
    --commission-max-rate="0.20" \
    --commission-max-change-rate="0.01" \
    --min-self-delegation="1" \


sleep 6

VAL2_OP_ADDR=$($DAEMON_NAME q staking validators --home $VAL2HOME -o json | jq -r '.validators[1].operator_address')

echo "VAL2_OP_ADDR: $VAL2_OP_ADDR"

# create delegation to both validators from both delegators 
$DAEMON_NAME tx staking delegate $VAL1_OP_ADDR  3000000000ubtsg --from $DEL1 --gas auto --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL1HOME -y
$DAEMON_NAME tx staking delegate $VAL2_OP_ADDR  100000000ubtsg --from $DEL2 --gas auto --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL2HOME  -y
sleep 6
# delegate from slashed del to non slashed val
$DAEMON_NAME tx staking delegate $VAL1_OP_ADDR  100000000ubtsg --from $DEL2 --gas auto --gas-adjustment 1.2  --home $VAL2HOME --chain-id $CHAINID -y
C
# stop bitsongd process for val2 for 1 block 
kill $VAL2_PID
sleep 60

# restart val2 
$DAEMON_NAME start --home $VAL2HOME

# confirm error exists with reward query



