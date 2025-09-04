#!/bin/bash
####################################################################
# A. START
####################################################################

# bitsongd sub-1 ./data 26657 26656 6060 9090 ubtsg
BIND=bitsongd
CHAINID=test-1
CHAINDIR=./data

VAL1HOME=$CHAINDIR/$CHAINID/val1
# Define the new ports for val1
VAL1_API_PORT=1317
VAL1_GRPC_PORT=9090
VAL1_GRPC_WEB_PORT=9091
VAL1_PROXY_APP_PORT=26658
VAL1_RPC_PORT=26657
VAL1_PPROF_PORT=6060
VAL1_P2P_PORT=26656

 
 

echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "Creating $BINARY instance for VAL1: home=$VAL1HOME | chain-id=$CHAINID | p2p=:$VAL1_P2P_PORT | rpc=:$VAL1_RPC_PORT | profiling=:$VAL1_PPROF_PORT | grpc=:$VAL1_GRPC_PORT"
trap 'pkill -f '"$BIND" EXIT
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"

defaultCoins="100000000000000ubtsg"  # 1M
fundCommunityPool="1000000000ubtsg" # 1K
delegate="1000000ubtsg" # 1btsg

rm -rf $VAL1HOME  
# # Clone the repository if it doesn't exist
# git clone https://github.com/permissionlessweb/go-bitsong
# # # Change into the cloned directory
# cd go-bitsong &&
# # # Checkout the version of go-bitsong that doesnt submit slashing hooks
# git checkout main
# make install 
# cd ../ &&

rm -rf $VAL1HOME/test-keys

$BIND init $CHAINID --overwrite --home $VAL1HOME --chain-id $CHAINID
sleep 1

mkdir $VAL1HOME/test-keys
# cli config
$BIND --home $VAL1HOME config keyring-backend test
 
sleep 1
$BIND --home $VAL1HOME config chain-id $CHAINID_A
sleep 1
$BIND --home $VAL1HOME config node tcp://localhost:$VAL1_RPC_PORT
sleep 1


# modify val1 genesis 
jq ".app_state.crisis.constant_fee.denom = \"ubtsg\" |
        .app_state.staking.params.bond_denom = \"ubtsg\" |
        .app_state.mint.params.blocks_per_year = \"31536000\" | # Assuming a non-leap year for simplicity
        .app_state.mint.params.mint_denom = \"ubtsg\" |
        .app_state.protocolpool.params.enabled_distribution_denoms[0] = \"stake\" |
        .app_state.gov.voting_params.voting_period = \"30s\" |
        .app_state.gov.params.expedited_voting_period = \"10s\" |
        .app_state.gov.params.voting_period = \"15s\" |
        .app_state.gov.params.expedited_min_deposit[0].denom = \"ubtsg\" |
        .app_state.gov.params.min_deposit[0].denom = \"ubtsg\" |
        .app_state.fantoken.params.burn_fee.denom = \"ubtsg\" |
        .app_state.fantoken.params.issue_fee.denom = \"ubtsg\" |
        .app_state.slashing.params.signed_blocks_window = \"100\" | # Example adjustment for slashing window
        .app_state.slashing.params.min_signed_per_window = \"0.500000000000000000\" | # Adjust according to your needs
        .app_state.fantoken.params.mint_fee.denom = \"ubtsg\" |
        .consensus_params.block.time_iota_ms = \"1000\"" $VAL1HOME/config/genesis.json > $VAL1HOME/config/tmp.json
# give val2 a genesis
mv $VAL1HOME/config/tmp.json $VAL1HOME/config/genesis.json

# setup test keys.
yes | $BIND  --home $VAL1HOME keys add validator1 --output json > $VAL1HOME/test-keys/val.json 2>&1 
sleep 1
yes | $BIND  --home $VAL1HOME keys add user --output json > $VAL1HOME/test-keys/user.json 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add delegator1 --output json > $VAL1HOME/test-keys/del.json 2>&1
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account "$($BIND --home $VAL1HOME keys show user -a)" $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account "$($BIND --home $VAL1HOME keys show validator1 -a)" $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account "$($BIND --home $VAL1HOME keys show delegator1 -a)" $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis gentx validator1 $delegate --chain-id $CHAINID 
sleep 1
$BIND genesis collect-gentxs --home $VAL1HOME
sleep 1


# keys 
DEL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/del.json)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/$CHAINID/val1/test-keys/del.json)
VAL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/val.json)
USERADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val1/test-keys/user.json)


# app & config modiifications
# config.toml
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL1_PROXY_APP_PORT\"/g" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL1_RPC_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL1_RPC_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL1_P2P_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL1HOME/config/config.toml &&
 
# app.toml
sed -i.bak "/^\[api\]/,/^\[/ s/minimum-gas-prices.*/minimum-gas-prices = \"0.0ubtsg\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[api\]/,/^\[/ s/address.*/address = \"tcp:\/\/0.0.0.0:$VAL1_API_PORT\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[grpc\]/,/^\[/ s/address.*/address = \"localhost:$VAL1_GRPC_PORT\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[grpc-web\]/,/^\[/ s/address.*/address = \"localhost:$VAL1_GRPC_WEB_PORT\"/" $VAL1HOME/config/app.toml &&
 

# Start bitsong
echo "Starting Genesis validator..."
$BIND start --home $VAL1HOME & 
VAL1_PID=$!
echo "VAL1_PID: $VAL1_PID"
sleep 6

####################################################################
# B. UPLOAD & REGISTER CONTRACT TO CADENCE
####################################################################

# -------------------- configuration --------------------
CADENCE_WASM="./cadence_example.wasm"
DEFAULT_GAS_LIMIT=200000
LOW_GAS_LIMIT=65000
sleep 6
echo "Storing Cadence contract WASM ($CADENCE_WASM)…"
$BIND tx wasm store "$CADENCE_WASM" --home $VAL1HOME --from $DEL1 -y --fees 400000ubtsg --gas auto --gas-adjustment 1.3
sleep 6
CODE_ID=1
echo "Initializing code-id $CODE_ID"
$BIND tx wasm i 1 '{}' --from $DEL1 --home $VAL1HOME --no-admin --label="metro" --fees 400000ubtsg --gas auto --gas-adjustment 1.3 --keyring-backend test -y 
sleep 6
CONTRACT_ADDR=$($BIND q wasm lca 1 --home $VAL1HOME -o json | jq -r .contracts[0])
if [ -z "$CONTRACT_ADDR" ]; then
  echo "Failed to register contract – cannot find contract_address"
  echo "$CONTRACT_ADDR"
  exit 1
fi
echo "contract address=$CONTRACT_ADDR"
echo "Registering contract (CONTRACT_ADDR=$CONTRACT_ADDR)…"
$BIND tx cade register $CONTRACT_ADDR --home $VAL1HOME --from $DEL1ADDR --fees 700000ubtsg --gas auto --gas-adjustment 1.3 --keyring-backend test -y 
sleep 6
OUTPUT=$($BIND q wasm contract-state smart $CONTRACT_ADDR '{"get_config":{}}' -o json)
echo "$OUTPUT"
VAL=$(echo "$OUTPUT" | jq -r '.data.val')
echo "VAL: $VAL"
if [ "$VAL" != "0" ]; then
  echo "Expected initial value 0, got $VAL"
  exit 1
fi
sleep 6

# -------------------- 5. query after first block (should be 1) --------------------
VAL=$($BIND q wasm contract-state smart $CONTRACT_ADDR '{"get_config":{}}' --home "$VAL1HOME" -o json | jq -r '.data.val')
if [ "$VAL" -le "1" ]; then
echo "Expected initial value 1, got $VAL"
exit 1
fi
sleep 6

# -------------------- 8. verify jail status --------------------
JAILED=$($BIND query cade contract "$CONTRACT_ADDR" --home "$VAL1HOME" -o json | jq -r .is_jailed)
[ "$JAILED" != "true" ] && { echo "Contract expected to be jailed got $JAILED"; exit 1; }

if [ "$JAILED" != "true" ]; then
  echo "Expected initial value 0, got $VAL"
  exit 1
fi
 -------------
$BIND tx cade unjail "$CONTRACT_ADDR" false $TX_FLAGS >/dev/null

# -------------------- 12. final block --------------------
sleep 6

# -------------------- 13. final query (should be 2) --------------------
VAL=$($BIND q wasm contract-state smart $CONTRACT_ADDR '{"history":{}}' -o json)
[ "$VAL" != "2" ] && { echo "Expected final value 2, got $VAL"; exit 1; }

echo "Cadence contract workflow completed successfully"