
####################################################################
# A. START
####################################################################

# bitsongd sub-1 ./data 26657 26656 6060 9090 ubtsg
BIND=bitsongd
CHAINID=test-1
CHAINDIR=./data

VAL1HOME=$CHAINDIR/$CHAINID/val1
VAL2HOME=$CHAINDIR/$CHAINID/val2
VAL3HOME=$CHAINDIR/$CHAINID/val3
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
# Define the new ports for val3
VAL3_API_PORT=1319
VAL3_GRPC_PORT=9398
VAL3_GRPC_WEB_PORT=9399
VAL3_PROXY_APP_PORT=9397
VAL3_RPC_PORT=26457
VAL3_PPROF_PORT=6461
VAL3_P2P_PORT=26456

# upgrade details
UPGRADE_VERSION_TITLE="v0.20.0"
UPGRADE_VERSION_TAG="v020"
UPGRADE_INFO='{"binaries": {"linux/amd64": "https://github.com/bitsongofficial/go-bitsong/releases/download/v0.20.0/bitsongd"}}'

echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "Creating $BINARY instance for VAL1: home=$VAL1HOME | chain-id=$CHAINID | p2p=:$VAL1_P2P_PORT | rpc=:$VAL1_RPC_PORT | profiling=:$VAL1_PPROF_PORT | grpc=:$VAL1_GRPC_PORT"
echo "Creating $BINARY instance for VAL2: home=$VAL2HOME | chain-id=$CHAINID | p2p=:$VAL2_P2P_PORT | rpc=:$VAL2_RPC_PORT | profiling=:$VAL2_PPROF_PORT | grpc=:$VAL2_GRPC_PORT"
echo "Creating $BINARY instance for VAL2: home=$VAL3HOME | chain-id=$CHAINID | p2p=:$VAL3_P2P_PORT | rpc=:$VAL3_RPC_PORT | profiling=:$VAL3_PPROF_PORT | grpc=:$VAL3_GRPC_PORT"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"
echo "»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
echo "««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««"

defaultCoins="100000000000ubtsg"  # 100K
nonSlashedDelegation="100000000ubtsg" # 100
delegate="1000000ubtsg" # 1btsg

rm -rf $VAL1HOME $VAL2HOME 
# - init, config, and start the network using v018 of bitsong.
if [ -d "go-bitsong" ]; then
  # Change into the existing directory
  cd go-bitsong
  # Checkout the v0.18.1 branch
  git fetch
  # Pull the latest changes from the branch
  git pull origin v0.18.1
  make install 
else
  # Clone the repository if it doesn't exist
  git clone https://github.com/bitsongofficial/go-bitsong
  # Change into the cloned directory
  cd go-bitsong
  make install 
fi

# ## build the v19 patch (gov msg)
# git checkout v019 && make build
cd ../ &&

rm -rf $VAL1HOME/test-keys
rm -rf $VAL2HOME/test-keys
rm -rf $VAL3HOME/test-keys

$BIND init $CHAINID --overwrite --home $VAL1HOME --chain-id $CHAINID
sleep 1
$BIND init $CHAINID --overwrite --home $VAL2HOME --chain-id $CHAINID
sleep 1
$BIND init $CHAINID --overwrite --home $VAL3HOME --chain-id $CHAINID

mkdir $VAL1HOME/test-keys
mkdir $VAL2HOME/test-keys
mkdir $VAL3HOME/test-keys

$BIND --home $VAL1HOME config keyring-backend test
sleep 1
$BIND --home $VAL2HOME config keyring-backend test
sleep 1
$BIND --home $VAL3HOME config keyring-backend test

# remove val2 genesis
rm -rf $VAL2HOME/config/genesis.json &&
rm -rf $VAL3HOME/config/genesis.json &&
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
# give val2 a genesis
mv $VAL1HOME/config/tmp.json $VAL1HOME/config/genesis.json

# setup test keys.
yes | $BIND  --home $VAL1HOME keys add validator1  --output json > $VAL1HOME/test-keys/val.json 2>&1 
sleep 1
yes | $BIND --home $VAL2HOME keys add validator2  --output json > $VAL2HOME/test-keys/val.json 2>&1
sleep 1
yes | $BIND --home $VAL3HOME keys add validator3  --output json > $VAL3HOME/test-keys/validator3_seed.json 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add user    --output json > $VAL1HOME/test-keys/key_seed.json 2>&1
sleep 1
yes | $BIND  --home $VAL2HOME keys add relayer --output json > $VAL2HOME/test-keys/relayer_seed.json 2>&1
sleep 1
yes | $BIND  --home $VAL1HOME keys add delegator1 --output json > $VAL1HOME/test-keys/del.json 2>&1
sleep 1
yes | $BIND  --home $VAL2HOME keys add delegator2  --output json > $VAL2HOME/test-keys/del.json 2>&1
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL1HOME keys show user -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL2HOME keys show relayer -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL1HOME keys show validator1 -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL2HOME keys show validator2 -a) $defaultCoins
sleep 1
$BIND --home $VAL1HOME genesis add-genesis-account $($BIND --home $VAL3HOME keys show validator3 -a) $defaultCoins
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
cp $VAL1HOME/config/genesis.json $VAL3HOME/config/genesis.json
VAL1_P2P_ADDR=$($BIND tendermint show-node-id --home $VAL1HOME)@localhost:$VAL1_P2P_PORT


# keys 
DEL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/del.json)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/$CHAINID/val1/test-keys/del.json)
DEL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/del.json)
DEL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/del.json)
VAL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/val.json)
VAL1ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val1/test-keys/val.json)
VAL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/val.json)
VAL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/val.json)


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
# val3
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL3_PROXY_APP_PORT\"/g" $VAL3HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL3_RPC_PORT\"/" $VAL3HOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL3_RPC_PORT\"/" $VAL3HOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL3_P2P_PORT\"/" $VAL3HOME/config/config.toml &&
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$VAL1_P2P_ADDR\"/" $VAL3HOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL3HOME/config/config.toml &&

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
$BIND start --home $VAL1HOME & 
VAL1_PID=$!
echo "VAL1_PID: $VAL1_PID"
sleep 7


####################################################################
# B. SLASH
####################################################################
 
bitsongd start --home $VAL2HOME &
VAL2_PID=$!
echo "VAL2_PID: $VAL2_PID"

# let val2 catch up
sleep 3

VAL1_OP_ADDR=$($BIND q staking validators --home $VAL1HOME -o json | jq -r '.validators[0].operator_address')
echo "VAL1_OP_ADDR: $VAL1_OP_ADDR"

# create validator
bitsongd tx staking create-validator \
    --amount=9000000000ubtsg \
    --pubkey=$($BIND tendermint show-validator --home $VAL2HOME ) \
    --moniker="VAL2" \
    --chain-id=$CHAINID \
    --home $VAL2HOME \
    --from=$VAL2 \
    --commission-rate="0.10" \
    --commission-max-rate="0.20" \
    --commission-max-change-rate="0.01" \
    --min-self-delegation="1" \
    --fees="200ubtsg" \
    -y
sleep 6

# if this value is the same as val1, lets choose the validator[0]
VAL2_OP_ADDR=$($BIND q staking validators --home $VAL2HOME -o json | jq -r ".validators[] | select(.operator_address!= \"$VAL1_OP_ADDR\") |.operator_address" | head -1)
echo "VAL2_OP_ADDR: $VAL2_OP_ADDR"


# create delegation to both validators from both delegators 
$BIND tx staking delegate $VAL1_OP_ADDR 99000000ubtsg --from $DEL1 --gas auto  --fees 200ubtsg --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL1HOME -y 
$BIND tx staking delegate $VAL2_OP_ADDR 400000000ubtsg --from $DEL2 --gas auto --fees 800ubtsg --gas-adjustment 1.4 --chain-id $CHAINID --home $VAL2HOME -y
sleep 6
$BIND tx staking delegate $VAL2_OP_ADDR 99000000ubtsg --from $DEL1 --gas auto  --fees 800ubtsg --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL1HOME -y 
# stop bitsongd process for val2 for 1 block 
kill $VAL1_PID

# slash & jail val1
sleep 24

# restart val1
$BIND start --home $VAL1HOME &
sleep 10


####################################################################
# C. UPGRADE
####################################################################

# ## v0.19.0 image in prep for upgrade 
pkill -f bitsongd
cd go-bitsong
git checkout v0.19.0
make install 
cd ../ 
sleep 1

bitsongd start --home $VAL1HOME &
bitsongd start --home $VAL2HOME &
echo "waiting for validators to print blocks"
sleep 6

LATEST_HEIGHT=$( $BIND status --home $VAL1HOME | jq -r '.SyncInfo.latest_block_height' )
UPGRADE_HEIGHT=$(( $LATEST_HEIGHT + 10 ))
echo "$UPGRADE_HEIGHT"
sleep 6

echo "propose upgrade"
$BIND tx gov submit-legacy-proposal software-upgrade v020 --upgrade-height $UPGRADE_HEIGHT --upgrade-info="$UPGRADE_INFO" --title $UPGRADE_VERSION_TITLE --description="upgrade test" --from user --fees 1000ubtsg --deposit 5000000000ubtsg --gas auto --gas-adjustment 1.3 --no-validate --home $VAL1HOME -y
sleep 6

# echo "vote upgrade"
$BIND tx gov vote 1 yes --from $DEL1 --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL1HOME -y
$BIND tx gov vote 1 yes --from $DEL2 --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL2HOME -y
$BIND tx gov vote 1 yes --from $VAL1 --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL1HOME -y
$BIND tx gov vote 1 yes --from $VAL2 --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL2HOME -y
sleep 60


VAL1_OP_ADDR=$(jq -r '.body.messages[0].validator_address' $VAL1HOME/config/gentx/gentx-*.json)
VAL2_OP_ADDR=$($BIND q staking validators --home $VAL1HOME -o json | jq -r ".validators[] | select(.operator_address!= \"$VAL1_OP_ADDR\") |.operator_address" | head -1)
echo "VAL1_OP_ADDR: $VAL1_OP_ADDR"
echo "VAL2_OP_ADDR: $VAL2_OP_ADDR"
echo "DEL1ADDR: $DEL1ADDR"
echo "DEL2ADDR: $DEL2ADDR"

echo "querying rewards and balances pre upgrade"

DEL1_PRE_UPGR_REWARD=$($BIND q distribution rewards $DEL1ADDR --home $VAL1HOME --output json)
DEL2_PRE_UPGR_REWARD=$($BIND q distribution rewards $DEL2ADDR --home $VAL1HOME --output json)

echo "DEL1_PRE_UPGR_REWARD: $DEL1_PRE_UPGR_REWARD"
echo "DEL2_PRE_UPGR_REWARD: $DEL2_PRE_UPGR_REWARD"

# Query delegations
echo "Querying delegations..."
DEL1_QUERY=$($BIND q staking delegation $DEL1ADDR $VAL1_OP_ADDR --home $VAL1HOME -o json)
DEL2_QUERY=$($BIND q staking delegation $DEL2ADDR $VAL2_OP_ADDR --home $VAL2HOME -o json)
# echo "DEL1_QUERY: $DEL1_QUERY"
# echo "DEL2_QUERY: $DEL2_QUERY"

VAL1_DEL1_SHARES=$(echo "$DEL1_QUERY" | jq -r '.delegation.shares')
VAL1_DEL1_BTSG=$(echo "$DEL1_QUERY" | jq -r '.balance.amount')
VAL2_DEL2_SHARES=$(echo "$DEL2_QUERY" | jq -r '.delegation.shares')
VAL2_DEL2_BTSG=$(echo "$DEL2_QUERY" | jq -r '.balance.amount')
if [ -z "$VAL1_DEL1_SHARES" ] || [ -z "$VAL1_DEL1_BTSG" ] || [ -z "$VAL2_DEL2_SHARES" ] || [ -z "$VAL2_DEL2_BTSG" ]; then
  echo "Error: unable to extract delegation information."
  exit 1
fi

echo "VAL1_DEL1_SHARES: $VAL1_DEL1_SHARES"
echo "VAL1_DEL1_BTSG: $VAL1_DEL1_BTSG"
echo "VAL2_DEL2_SHARES: $VAL2_DEL2_SHARES"
echo "VAL2_DEL2_BTSG: $VAL2_DEL2_BTSG"
sleep 1

VAL1_OUTSTANDING_REWARDS=$($BIND q distribution validator-outstanding-rewards $VAL1_OP_ADDR --home $VAL1HOME -o json | jq -r '.rewards[] | select(.denom == "ubtsg") | .amount')
VAL1_TOTAL_SHARES=$($BIND q staking validator $VAL1_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegator_shares')
VAL1_TOTAL_TOKENS=$($BIND q staking validator $VAL1_OP_ADDR --home $VAL1HOME -o json | jq -r '.tokens')

VAL_COMMISSION="0.10"
VAL2_OUTSTANDING_REWARDS=$($BIND q distribution validator-outstanding-rewards $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.rewards[] | select(.denom == "ubtsg") | .amount')
VAL2_TOTAL_SHARES=$($BIND q staking validator $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegator_shares')
VAL2_TOTAL_TOKENS=$($BIND q staking validator $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.tokens')

echo "VAL1_OUTSTANDING_REWARDS:$VAL1_OUTSTANDING_REWARDS"
echo "VAL1_TOTAL_SHARES:$VAL1_TOTAL_SHARES"
echo "VAL1_TOTAL_TOKENS:$VAL1_TOTAL_TOKENS"
echo "VAL2_OUTSTANDING_REWARDS:$VAL2_OUTSTANDING_REWARDS"
echo "VAL2_TOTAL_SHARES:$VAL2_TOTAL_SHARES"
echo "VAL2_TOTAL_TOKENS:$VAL2_TOTAL_TOKENS"
sleep 1

# get balances for each addr prior to upgrade
DEL1_PRE_UPGR_BALANCE=$($BIND q bank balances $DEL1ADDR --home $VAL2HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
DEL2_PRE_UPGR_BALANCE=$($BIND q bank balances $DEL2ADDR --home $VAL2HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
VAL1_PRE_UPGR_BALANCE=$($BIND q bank balances $VAL1ADDR --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
VAL2_PRE_UPGR_BALANCE=$($BIND q bank balances $VAL2ADDR --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
echo "DEL1_PRE_UPGR_BALANCE:$DEL1_PRE_UPGR_BALANCE"
echo "DEL2_PRE_UPGR_BALANCE:$DEL2_PRE_UPGR_BALANCE"
echo "VAL1_PRE_UPGR_BALANCE:$VAL1_PRE_UPGR_BALANCE"
echo "VAL2_PRE_UPGR_BALANCE:$VAL2_PRE_UPGR_BALANCE"
echo "VAL2_PRE_UPGR_BALANCE:$VAL2_PRE_UPGR_BALANCE"
sleep 1

# kill nodes to upgrade to v0.20.1-print
pkill -f bitsongd
cd ./go-bitsong
make install 
cd .. 

# pkill -f bitsongd
# cd ../go-bitsong
# git checkout v0.20.1-print
# make install 
# cd ../

####################################################################
# C. CONFIRM
####################################################################
echo "performing v20 upgrade"
sleep 6

bitsongd start --home $VAL2HOME &
VAL2_PID=$!
echo "VAL2_PID: $VAL2_PID"

bitsongd start --home $VAL1HOME &
VAL1_PID=$!
echo "VAL1_PID: $VAL1_PID"
sleep 12


echo "check new balances"
DEL1_POST_UPGR_BALANCE=$($BIND q bank balances $DEL1ADDR --home $VAL2HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
DEL2_POST_UPGR_BALANCE=$($BIND q bank balances $DEL2ADDR --home $VAL2HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
VAL1_POST_UPGR_BALANCE=$($BIND q bank balances $VAL1ADDR --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
VAL2_POST_UPGR_BALANCE=$($BIND q bank balances $VAL2ADDR --home $VAL2HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
VAL1_POST_UPGR_OUT_REWARDS=$($BIND q distribution validator-outstanding-rewards $VAL1_OP_ADDR --output json | jq -r '.rewards[] | select(.denom == "ubtsg") | .amount')
VAL2_POST_UPGR_OUT_REWARDS=$($BIND q distribution validator-outstanding-rewards $VAL2_OP_ADDR --output json | jq -r '.rewards[] | select(.denom == "ubtsg") | .amount')
echo "DEL1_POST_UPGR_BALANCE: $DEL1_POST_UPGR_BALANCE"
echo "DEL2_POST_UPGR_BALANCE:$DEL2_POST_UPGR_BALANCE"
echo "VAL1_POST_UPGR_BALANCE:$VAL1_POST_UPGR_BALANCE"
echo "VAL2_POST_UPGR_BALANCE:$VAL2_POST_UPGR_BALANCE"
echo "VAL1_POST_UPGR_OUT_REWARDS:$VAL1_POST_UPGR_OUT_REWARDS"
echo "VAL2_POST_UPGR_OUT_REWARDS:$VAL2_POST_UPGR_OUT_REWARDS"
sleep 1

echo "check rewards have been redeemed"
DEL1_REWARDS=$($BIND q distribution rewards $DEL1ADDR --home $VAL1HOME --output json)
DEL2_REWARDS=$($BIND q distribution rewards $DEL2ADDR --home $VAL1HOME --output json)
sleep 1
echo "DEL1_REWARDS:$DEL1_REWARDS"
echo "DEL2_REWARDS:$DEL2_REWARDS"
echo "VAL1_REWARDS:$VAL1_REWARDS"
echo "VAL2_REWARDS:$VAL2_REWARDS"   
sleep 1

echo "redelegate from val1 to val2 "
REDEL=$($BIND q staking delegation $DEL1ADDR $VAL1_OP_ADDR --home $VAL1HOME -o json | jq -r '.balance.amount')ubtsg
$BIND tx staking redelegate $VAL1_OP_ADDR $VAL2_OP_ADDR 98010000ubtsg  \
--chain-id $CHAINID --home $CHAINDIR --from $VAL1 --home $VAL1HOME \
--gas auto --gas-adjustment 1.4 --fees 10000ubtsg -y
sleep 8

echo "accumulate rewards and query rewards... "
DEL1_PRE_MANU_CLAIM=$($BIND q bank balances $DEL1ADDR --output json --home $VAL2HOME | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
echo "DEL1_PRE_MANU_CLAIM:$DEL1_PRE_MANU_CLAIM"
sleep 8

echo "claim rewards... "
## withdraw all rewards for del
$BIND tx distribution withdraw-all-rewards \
--chain-id $CHAINID --home $CHAINDIR --from $DEL1 --home $VAL1HOME \
--gas auto --gas-adjustment 1.4 --fees 10000ubtsg -y
 
sleep 6

## confirm withdraw went to correct address
echo "confirm balance update... "
DEL1_POST_MANU_CLAIM=$($BIND q bank balances $DEL1ADDR --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
echo "DEL1_POST_MANU_CLAIM:$DEL1_POST_MANU_CLAIM"

sleep 1
if (($DEL1_PRE_MANU_CLAIM<$DEL1_POST_MANU_CLAIM )); then
    echo "GOOD claim. Balance has increased"
else
     echo "BAD CLAIM. Balance has not changed"
fi

echo "create slash event again..."
sleep 4

echo "confirm delegator balance still exists"
sleep 4