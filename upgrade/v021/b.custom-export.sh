#!/bin/bash
BIND=bitsongd
CHAINID_A=test-1
CHAINID_B=test-2

# setup test keys.
VAL=val
RELAYER=relayer
DEL=del
USER=user
DELFILE="test-keys/$DEL.json"
VALFILE="test-keys/$VAL.json"
RELAYERFILE="test-keys/$RELAYER.json"
USERFILE="test-keys/$USER.json"

# file paths
CHAINDIR=./data
VAL1HOME=$CHAINDIR/$CHAINID_A/val1
VAL2HOME=$CHAINDIR/$CHAINID_B/val1
HERMES=~/.hermes
 
# Define the new ports for val1 on chain a
VAL1_API_PORT=1317
VAL1_GRPC_PORT=9090
VAL1_GRPC_WEB_PORT=9091
VAL1_PROXY_APP_PORT=26658
VAL1_RPC_PORT=26657
VAL1_PPROF_PORT=6060
VAL1_P2P_PORT=26656

# Define the new ports for val1 on chain b
VAL2_API_PORT=1318
VAL2_GRPC_PORT=10090
VAL2_GRPC_WEB_PORT=10091
VAL2_PROXY_APP_PORT=9395
VAL2_RPC_PORT=27657
VAL2_PPROF_PORT=6361
VAL2_P2P_PORT=26356

echo "Creating $BINARY instance for VAL1: home=$VAL1HOME | chain-id=$CHAINID_A | p2p=:$VAL1_P2P_PORT | rpc=:$VAL1_RPC_PORT | profiling=:$VAL1_PPROF_PORT | grpc=:$VAL1_GRPC_PORT"
echo "Creating $BINARY instance for VAL2: home=$VAL2HOME | chain-id=$CHAINID_A | p2p=:$VAL2_P2P_PORT | rpc=:$VAL2_RPC_PORT | profiling=:$VAL2_PPROF_PORT | grpc=:$VAL2_GRPC_PORT"

defaultCoins="100000000000ubtsg"  # 100K
delegate="1000000ubtsg" # 1btsg


export PATH=$PATH:/usr/local/go/bin
source ~/.profile  # Or restart your shell

####################################################################
# A. CHAINS CONFIG
####################################################################

rm -rf $VAL1HOME $VAL2HOME 
rm -rf $VAL1HOME/test-keys
rm -rf $VAL2HOME/test-keys

# initialize chains
$BIND init $CHAINID_A --overwrite --home $VAL1HOME --chain-id $CHAINID_A
sleep 2
$BIND init $$CHAINID_A--overwrite --home $VAL2HOME --chain-id $CHAINID_A
sleep 1

mkdir $VAL1HOME/test-keys
mkdir $VAL2HOME/test-keys

# cli config
$BIND --home $VAL1HOME config keyring-backend test
$BIND --home $VAL2HOME config keyring-backend test
sleep 1
$BIND --home $VAL1HOME config chain-id $CHAINID_A
$BIND --home $VAL2HOME config chain-id $CHAINID_A
sleep 1
$BIND --home $VAL1HOME config node tcp://localhost:$VAL1_RPC_PORT
$BIND --home $VAL2HOME config node tcp:\/\/127.0.0.1:$VAL2_RPC_PORT
sleep 1
  

yes | $BIND  --home $VAL1HOME keys add $VAL --output json > $VAL1HOME/$VALFILE 2>&1 
sleep 1
yes | $BIND  --home $VAL2HOME keys add $VAL --output json > $VAL2HOME/$VALFILE 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add $USER --output json > $VAL1HOME/$USERFILE 2>&1
sleep 1
yes | $BIND  --home $VAL2HOME keys add user --output json > $VAL2HOME/$USERFILE 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add $DEL --output json > $VAL1HOME/$DELFILE 2>&1
sleep 1
yes | $BIND  --home $VAL2HOME keys add $DEL  --output json > $VAL2HOME/$DELFILE 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add $RELAYER  --output json > $VAL1HOME/$RELAYERFILE 2>&1
sleep 1
RELAYERADDR=$(jq -r '.address' $VAL1HOME/$RELAYERFILE)
DEL1ADDR=$(jq -r '.address' $VAL1HOME/$DELFILE)
DEL2ADDR=$(jq -r '.address'  $VAL2HOME/$DELFILE)
VAL1A_ADDR=$(jq -r '.address'  $VAL1HOME/$VALFILE)
VAL1B_ADDR=$(jq -r '.address'  $VAL2HOME/$VALFILE)
USERAADDR=$(jq -r '.address' $VAL1HOME/$USERFILE)
USERBADDR=$(jq -r '.address' $VAL2HOME/$USERFILE)


 ####################################################################
# 0. SNAPSHOT CONFIG 
####################################################################
echo "unzipping snapshot..."
# create export 
lz4 -c -d ./bin/bitsong_20730391.tar.lz4  | tar -x -C $VAL1HOME

echo "creating testnet-from-export"
# create testnet-from-export
$BIND export --for-zero-height --output-document $VAL1HOME/config/genesis.json

# copy genesis into second val 
cp $VAL1HOME/config/genesis.json $VAL2HOME/config/genesis.json

# app & config modiifications
# config.toml2
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL1_PROXY_APP_PORT\"/g" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL1_RPC_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL1_RPC_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL1_P2P_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL1HOME/config/config.toml &&
sed -i.bak -e "s/^pprof_laddr *=.*/pprof_laddr = \"localhost:6060\"/g" $VAL1HOME/config/config.toml &&
# val2
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL2_PROXY_APP_PORT\"/g" $VAL2HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL2_RPC_PORT\"/" $VAL2HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL2_RPC_PORT\"/" $VAL2HOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL2_P2P_PORT\"/" $VAL2HOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL2HOME/config/config.toml &&
sed -i.bak -e "s/^pprof_laddr *=.*/pprof_laddr = \"localhost:6070\"/g" $VAL2HOME/config/config.toml &&
# app.toml
sed -i.bak "/^\[api\]/,/^\[/ s/minimum-gas-prices.*/minimum-gas-prices = \"0.0ubtsg\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[api\]/,/^\[/ s/address.*/address = \"tcp:\/\/0.0.0.0:$VAL1_API_PORT\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[grpc\]/,/^\[/ s/address.*/address = \"localhost:$VAL1_GRPC_PORT\"/" $VAL1HOME/config/app.toml &&
sed -i.bak "/^\[grpc-web\]/,/^\[/ s/address.*/address = \"localhost:$VAL1_GRPC_WEB_PORT\"/" $VAL1HOME/config/app.toml &&
# val2
sed -i.bak "/^\[api\]/,/^\[/ s/minimum-gas-prices.*/minimum-gas-prices = \"0.0ubtsg\"/" $VAL2HOME/config/app.toml &&
sed -i.bak "/^\[api\]/,/^\[/ s/address.*/address = \"tcp:\/\/0.0.0.0:$VAL2_API_PORT\"/" $VAL2HOME/config/app.toml &&
sed -i.bak "/^\[grpc\]/,/^\[/ s/address.*/address = \"localhost:$VAL2_GRPC_PORT\"/" $VAL2HOME/config/app.toml &&
sed -i.bak "/^\[grpc-web\]/,/^\[/ s/address.*/address = \"localhost:$VAL2_GRPC_WEB_PORT\"/" $VAL2HOME/config/app.toml &&

echo "starting validators..."
# # Start chains
# echo "Starting chain 1..."
# $BIND start --home $VAL1HOME & 
# VAL1A_PID=$!
# echo "VAL1A_PID: $VAL1A_PID"
# echo "Starting chain 2..."
# $BIND start --home $VAL2HOME & 
# VAL1B_PID=$!
# echo "VAL1B_PID: $VAL1B_PID"
# sleep 10

echo "RELAYERADDR: $RELAYERADDR"
echo "DEL1ADDR: $DEL1ADDR"
echo "DEL2ADDR: $DEL2ADDR"
echo "VAL1A_ADDR: $VAL1A_ADDR"
echo "VAL1B_ADDR: $VAL1B_ADDR"
echo "USERAADDR: $USERAADDR"
echo "USERBADDR: $USERBADDR"