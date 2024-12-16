# bitsongd sub-1 ./data 26657 26656 6060 9090 ubtsg
BIND=bitsongd
CHAINID=test-1
CHAINDIR=./data

VAL1HOME=$CHAINDIR/$CHAINID/val1
VAL2HOME=$CHAINDIR/$CHAINID/val2
# Define the new ports for val1
VAL1_API_PORT=1317
VAL1_GRPC_PORT=9090
VAL1_GRPC_WEB_PORT=9091
VAL1_PROXY_APP_PORT=26658
VAL1_RPC_PORT=26657
VAL1_PPROF_PORT=6060
VAL1_P2P_PORT=26656

# Define the new ports for val2
VAL2_API_PORT=1318
VAL2_GRPC_PORT=9393
VAL2_GRPC_WEB_PORT=9394
VAL2_PROXY_APP_PORT=9395
VAL2_RPC_PORT=26357
VAL2_PPROF_PORT=6361
VAL2_P2P_PORT=26356


echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "Creating $BINARY instance for VAL1: home=$VAL1HOME | chain-id=$CHAINID | p2p=:$VAL1_P2P_PORT | rpc=:$VAL1_RPC_PORT | profiling=:$VAL1_PPROF_PORT | grpc=:$VAL1_GRPC_PORT"
echo "Creating $BINARY instance for VAL2: home=$VAL2HOME | chain-id=$CHAINID | p2p=:$VAL2_P2P_PORT | rpc=:$VAL2_RPC_PORT | profiling=:$VAL2_PPROF_PORT | grpc=:$VAL2_GRPC_PORT"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"

defaultCoins="100000000000ubtsg"  # 100K
nonSlashedDelegation="100000000ubtsg" # 100
delegate="1000000000ubtsg" # 1K

rm -rf $VAL1HOME $VAL2HOME 
# - init, config, and start the network using v018 of bitsong.
# if [ -d "go-bitsong" ]; then
#   # Change into the existing directory
#   cd go-bitsong
#   # Checkout the v0.18.1 branch
#   git fetch
#   # Pull the latest changes from the branch
#   git pull origin v0.18.1
#   make install 
# else
#   # Clone the repository if it doesn't exist
#   git clone https://github.com/bitsongofficial/go-bitsong
#   # Change into the cloned directory
#   cd go-bitsong
#   make install 
# fi

# ## build the v19 patch (gov msg)
# git checkout v019 && make build
# cd ../ &&

rm -rf $VAL1HOME/test-keys
rm -rf $VAL2HOME/test-keys


$BIND init $CHAINID --overwrite --home $VAL1HOME --chain-id $CHAINID
sleep 1
$BIND init $CHAINID --overwrite --home $VAL2HOME --chain-id $CHAINID

mkdir $VAL1HOME/test-keys
mkdir $VAL2HOME/test-keys
$BIND --home $VAL1HOME config keyring-backend test
sleep 1
$BIND --home $VAL2HOME config keyring-backend test
# remove val2 genesis
rm -rf $VAL2HOME/config/genesis.json &&
# modify val1 genesis 
jq ".app_state.crisis.constant_fee.denom = \"ubtsg\" |
      .app_state.staking.params.bond_denom = \"ubtsg\" |
      .app_state.mint.params.blocks_per_year = \"20000000\" |
      .app_state.mint.params.mint_denom = \"ubtsg\" |
      .app_state.merkledrop.params.creation_fee.denom = \"ubtsg\" |
      .app_state.gov.voting_params.voting_period = \"15s\" |
      .app_state.gov.params.voting_period = \"15s\" |
      .app_state.gov.params.min_deposit[0].denom = \"ubtsg\" |
      .app_state.fantoken.params.burn_fee.denom = \"ubtsg\" |
      .app_state.fantoken.params.issue_fee.denom = \"ubtsg\" |
      .app_state.slashing.params.signed_blocks_window = \"10\" |
      .app_state.slashing.params.min_signed_per_window = \"1.000000000000000000\" |
      .app_state.fantoken.params.mint_fee.denom = \"ubtsg\"" $VAL1HOME/config/genesis.json > $VAL1HOME/config/tmp.json

mv $VAL1HOME/config/tmp.json $VAL1HOME/config/genesis.json


# setup test keys.
yes | $BIND  --home $VAL1HOME keys add validator1  --output json > $VAL1HOME/test-keys/validator1_seed.json 2>&1 
sleep 1
yes | $BIND --home $VAL2HOME keys add validator2  --output json > $VAL2HOME/test-keys/validator2_seed.json 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add user    --output json > $VAL1HOME/test-keys/key_seed.json 2>&1
sleep 1
yes | $BIND  --home $VAL2HOME keys add relayer --output json > $VAL2HOME/test-keys/relayer_seed.json 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add delegator1 --output json > $VAL1HOME/test-keys/delegator1_seed.json 2>&1
sleep 1
yes | $BIND  --home $VAL2HOME keys add delegator2  --output json > $VAL2HOME/test-keys/delegator2_seed.json 2>&1
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL1HOME keys show user -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL2HOME keys show relayer -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL1HOME keys show validator1 -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL2HOME keys show validator2 -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL1HOME keys show delegator1 -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL2HOME keys show delegator2 -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis gentx validator1 $delegate --chain-id $CHAINID 
sleep 1
$BIND genesis collect-gentxs --home $VAL1HOME
sleep 1
cp $VAL1HOME/config/genesis.json $VAL2HOME/config/genesis.json
VAL1_P2P_ADDR=$($BIND tendermint show-node-id --home $VAL1HOME)@localhost:$VAL1_P2P_PORT


# app & config modiifications
# config.toml
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL1_PROXY_APP_PORT\"/g" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL1_RPC_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL1_RPC_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL1_P2P_PORT\"/" $VAL1HOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL1HOME/config/config.toml &&
# val2
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL2_PROXY_APP_PORT\"/g" $VAL2HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL2_RPC_PORT\"/" $VAL2HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL2_RPC_PORT\"/" $VAL2HOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL2_P2P_PORT\"/" $VAL2HOME/config/config.toml &&
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$VAL1_P2P_ADDR\"/" $VAL2HOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL2HOME/config/config.toml &&

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


# Start bitsong
echo "Starting Genesis validator..."
echo $($BIND tendermint show-node-id --home $VAL1HOME)
echo $($VAL1_P2P_ADDR)
$BIND start --home $VAL1HOME