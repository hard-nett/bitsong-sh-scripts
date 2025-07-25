#!/bin/bash

BIND=bitsongd
CHAINID=test-1
UPGRADE_VERSION=v023

SNAPSHOT_PATH=./bin/bitsong_22929623.tar.lz4

# file paths
CHAINDIR=./data
VAL1HOME=$CHAINDIR/$CHAINID/val1
 
# Define the new ports for val1 on chain a
VAL1_API_PORT=1317
VAL1_GRPC_PORT=9090
VAL1_GRPC_WEB_PORT=9091
VAL1_PROXY_APP_PORT=26658
VAL1_RPC_PORT=26657
VAL1_PPROF_PORT=6060
VAL1_P2P_PORT=26656
 

echo "Creating $BINARY instance for VAL1: home=$VAL1HOME | chain-id=$CHAINID | p2p=:$VAL1_P2P_PORT | rpc=:$VAL1_RPC_PORT | profiling=:$VAL1_PPROF_PORT | grpc=:$VAL1_GRPC_PORT"
trap 'pkill -f '"$BIND" EXIT

# Clone the repository if it doesn't exist
git clone https://github.com/permissionlessweb/go-bitsong
# # Change into the cloned directory
cd go-bitsong &&
# # Checkout the version of go-bitsong that doesnt submit slashing hooks
git checkout feat/rs-bitsong
make install 
cd ../ &&



####################################################################
# A. CHAINS CONFIG
####################################################################

rm -rf $VAL1HOME 
rm -rf $VAL1HOME/test-keys

# initialize chains
$BIND init $CHAINID --overwrite --home $VAL1HOME --chain-id $CHAINID
sleep 2
mkdir $VAL1HOME/test-keys

# cli config
$BIND --home $VAL1HOME config keyring-backend test
sleep 1
$BIND --home $VAL1HOME config chain-id $CHAINID
sleep 1
$BIND --home $VAL1HOME config node tcp://localhost:$VAL1_RPC_PORT
sleep 1
  
# setup test keys.
yes | $BIND  --home $VAL1HOME keys add validator1 --output json > $VAL1HOME/test-keys/val.json 2>&1 
sleep 1
yes | $BIND  --home $VAL1HOME keys add user --output json > $VAL1HOME/test-keys/user.json 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add delegator1 --output json > $VAL1HOME/test-keys/del.json 2>&1
sleep 1

DEL1=$(jq -r '.name' $CHAINDIR/"$CHAINID"/val1/test-keys/del.json)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/"$CHAINID"/val1/test-keys/del.json)
VAL1=$(jq -r '.name' $CHAINDIR/"$CHAINID"/val1/test-keys/val.json)
USERADDR=$(jq -r '.address'  $CHAINDIR/"$CHAINID"/val1/test-keys/user.json)

# app & config modiifications
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL1_PROXY_APP_PORT\"/g" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL1_RPC_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL1_RPC_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL1_P2P_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL1HOME/config/config.toml &&
sed -i.bak -e "s/^pprof_laddr *=.*/pprof_laddr = \"localhost:6060\"/g" $VAL1HOME/config/config.toml &&
 
# app.toml
sed -i.bak "/^\[api\]/,/^\[/ s/minimum-gas-prices.*/minimum-gas-prices = \"0.0ubtsg\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[api\]/,/^\[/ s/address.*/address = \"tcp:\/\/0.0.0.0:$VAL1_API_PORT\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[grpc\]/,/^\[/ s/address.*/address = \"localhost:$VAL1_GRPC_PORT\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[grpc-web\]/,/^\[/ s/address.*/address = \"localhost:$VAL1_GRPC_WEB_PORT\"/" $VAL1HOME/config/app.toml &&
 
 
####################################################################
# 0. SNAPSHOT CONFIG 
####################################################################
echo "unzipping snapshot..."
# create export 
lz4 -c -d  $SNAPSHOT_PATH | tar -x -C $VAL1HOME

echo "creating testnet-from-export"
# create testnet-from-export
$BIND in-place-testnet "$CHAINID" "$USERADDR" bitsongvaloper1qxw4fjged2xve8ez7nu779tm8ejw92rv0vcuqr --trigger-testnet-upgrade $UPGRADE_VERSION  --home $VAL1HOME --skip-confirmation & 
INPLACE_TESTNET=$!
echo "INPLACE_TESTNET: $INPLACE_TESTNET"
sleep 100

####################################################################
# 0. UPGRADING
####################################################################
pkill -f $BIND
# Clone the repository if it doesn't exist
git clone https://github.com/permissionlessweb/go-bitsong
# # Change into the cloned directory
cd go-bitsong && git fetch &&
# # Checkout the version of go-bitsong that doesnt submit slashing hooks
git checkout main && git pull 
make install 
cd ../ &&

# Start bitsong
echo "Running upgradehandler to fix community-pool issue..."
$BIND start --home $VAL1HOME & 
VAL1_PID=$!
echo "VAL1_PID: $VAL1_PID"
sleep 7

####################################################################
# 0. CONFIRMING  
####################################################################
PROTOCOL_POOL_ADDR=$($BIND q auth module-account protocolpool --home $VAL1HOME -o json | jq -r '.account.value.address')
PROTOCOL_POOL_ESCROW_ADDR=$($BIND q auth module-account protocolpool_escrow --home $VAL1HOME -o json | jq -r '.account.value.address')
DISTRIBUTION_MODULE_ADDR=$($BIND q auth module-account distribution --home $VAL1HOME -o json  | jq -r '.account.value.address')

echo "PROTOCOL_POOL_ADDR: $PROTOCOL_POOL_ADDR"
echo "DISTRIBUTION_MODULE_ADDR: $DISTRIBUTION_MODULE_ADDR"
echo "PROTOCOL_POOL_ESCROW_ADDR: $PROTOCOL_POOL_ESCROW_ADDR"

# get balances for each addr prior to upgrade
POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG=$($BIND q bank balances "$PROTOCOL_POOL_ADDR" --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_BTSG=$($BIND q bank balances "$DISTRIBUTION_MODULE_ADDR" --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
# POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN=$($BIND q bank balances "$PROTOCOL_POOL_ADDR" --home $VAL1HOME --output json | jq -r".balances[] | select(.denom == \"$FANTOKEN\") | .amount")
# POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_FANTOKEN=$($BIND q bank balances  "$DISTRIBUTION_MODULE_ADDR" --home $VAL1HOME --output json | jq -r ".balances[] | select(.denom == \"$FANTOKEN\") | .amount")
# echo "PROTOCOL_POOL-FANTOKEN:$POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN"
# echo "DISTRIBUTION-FANTOKEN:$POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_FANTOKEN"
 

echo "PROTOCOL_POOL-BTSG:$POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG"
echo "DISTRIBUTION-BITSONG:$POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_BTSG"

## if protocol pool balances are not empty, exit 
if [ -n "$POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG" ]; then
  echo "Protocol pool balances are not empty. Exiting..."
  exit 1
fi

## check block rewards go to distribution module accurately
ABLOCK=$($BIND q distribution community-pool --home $VAL1HOME -o json | jq -r '.pool[0]' | sed 's/ubtsg$//' ) 
sleep 7
BBLOCK=$($BIND q distribution community-pool --home $VAL1HOME -o json | jq -r '.pool[0]' | sed 's/ubtsg$//' ) 
if (( $(echo "$BBLOCK > $ABLOCK" | bc -l) == 0 )); then
  echo "Error: BBLOCK ($BBLOCK) is not greater than ABLOCK ($ABLOCK)"
  pkill -f bitsongd
  exit 1
fi
sleep 7
OBLOCK=$($BIND q distribution community-pool --home $VAL1HOME -o json | jq -r '.pool[0]' | sed 's/ubtsg$//' ) 
if (( $(echo "$OBLOCK > $BBLOCK" | bc -l) == 0 )); then
  pkill -f bitsongd
  exit 1
fi

# ## ensure funding community pool is okay 
# MSG_CODE=$($BIND tx distribution fund-community-pool $fundCommunityPool --from="$DEL1" --gas auto --fees 200ubtsg --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL1HOME -o json -y | jq -r '.code')
# if [ -n "$MSG_CODE" ] && [ "$MSG_CODE" -ne 0 ]; then
#   exit 1
# fi

echo "COMMUNITY POOL PATCH APPLIED SUCCESSFULLY, ENDING TESTS"
pkill -f bitsongd