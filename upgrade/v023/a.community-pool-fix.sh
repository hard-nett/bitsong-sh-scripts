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

 
# upgrade details
UPGRADE_VERSION_TITLE="v0.23.0"
UPGRADE_VERSION_TAG="v023"

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
# Clone the repository if it doesn't exist
git clone https://github.com/permissionlessweb/go-bitsong
# # Change into the cloned directory
cd go-bitsong &&
# # Checkout the version of go-bitsong that doesnt submit slashing hooks
git checkout feat/rs-bitsong
make install 
cd ../ &&

rm -rf $VAL1HOME/test-keys

$BIND init $CHAINID --overwrite --home $VAL1HOME --chain-id $CHAINID
sleep 1

mkdir $VAL1HOME/test-keys

$BIND --home $VAL1HOME config keyring-backend test
sleep 1

# modify val1 genesis 
jq ".app_state.crisis.constant_fee.denom = \"ubtsg\" |
      .app_state.staking.params.bond_denom = \"ubtsg\" |
      .app_state.mint.params.blocks_per_year = \"10000000\" |
      .app_state.mint.params.mint_denom = \"ubtsg\" |
      .app_state.protocolpool.params.enabled_distribution_denoms[0] = \"stake\" |
      .app_state.gov.voting_params.voting_period = \"30s\" |
      .app_state.gov.params.expedited_voting_period = \"10s\" | 
      .app_state.gov.params.voting_period = \"15s\" |
      .app_state.gov.params.expedited_min_deposit[0].denom = \"ubtsg\" |
      .app_state.gov.params.min_deposit[0].denom = \"ubtsg\" |
      .app_state.fantoken.params.burn_fee.denom = \"ubtsg\" |
      .app_state.fantoken.params.issue_fee.denom = \"ubtsg\" |
      .app_state.slashing.params.signed_blocks_window = \"10\" |
      .app_state.slashing.params.min_signed_per_window = \"1.000000000000000000\" |
      .app_state.fantoken.params.mint_fee.denom = \"ubtsg\"" $VAL1HOME/config/genesis.json > $VAL1HOME/config/tmp.json
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
sleep 7


####################################################################
# B. FUND COMMUNITY POOL
####################################################################
PROTOCOL_POOL_ADDR=$($BIND q auth module-account protocolpool --home $VAL1HOME -o json | jq -r '.account.value.address')
PROTOCOL_POOL_ESCROW_ADDR=$($BIND q auth module-account protocolpool_escrow --home $VAL1HOME -o json | jq -r '.account.value.address')
DISTRIBUTION_MODULE_ADDR=$($BIND q auth module-account distribution --home $VAL1HOME -o json  | jq -r '.account.value.address')

echo "PROTOCOL_POOL_ADDR: $PROTOCOL_POOL_ADDR"
echo "DISTRIBUTION_MODULE_ADDR: $DISTRIBUTION_MODULE_ADDR"
echo "PROTOCOL_POOL_ESCROW_ADDR: $PROTOCOL_POOL_ESCROW_ADDR"
 
# create fantoken to send to community pool
ISSUE_FANTOKEN_TX_HASH=$($BIND tx fantoken issue --name="Kitty Token" --symbol="kitty" --max-supply="1000000000000" --uri="ipfs://..." --from "$DEL1" --chain-id $CHAINID --fees 200ubtsg --home $VAL1HOME  --output json -y | jq -r '.txhash')
sleep 7


FANTOKEN=$($BIND q tx "$ISSUE_FANTOKEN_TX_HASH" -o json --home $VAL1HOME | jq -r '.data' | xxd -r -p | awk -F '*' '/ft/ {print $2}')
echo "$FANTOKEN"
sleep 6

$BIND tx fantoken mint "1000000000000$FANTOKEN" --recipient="$DEL1ADDR" --from="$DEL1" --chain-id $CHAINID --fees 200ubtsg --home $VAL1HOME -y
sleep 6

# create delegation to both validators from both delegators 
$BIND tx protocolpool fund-community-pool 1000000000000"$FANTOKEN" --from="$DEL1" --gas auto --fees 200ubtsg --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL1HOME -y 
sleep 6
$BIND tx protocolpool fund-community-pool $fundCommunityPool  --from="$DEL1" --gas auto --fees 200ubtsg --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL1HOME -y 

## try fund community pool via distribution module is expected to error 
# $BIND tx distribution fund-community-pool $fundCommunityPool  --from="$DEL1" --gas auto --fees 200ubtsg --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL1HOME -y 

# we expect community pool query to work from protocolpool module
PBLOCK=$($BIND q protocolpool community-pool --home $VAL1HOME -o json ) 
echo "$PBLOCK"


####################################################################
# C. UPGRADE
####################################################################
echo "lets upgrade to revert to using x/distribution module "
sleep 6

LATEST_HEIGHT=$( $BIND status --home $VAL1HOME | jq -r '.sync_info.latest_block_height' )
UPGRADE_HEIGHT=$(( $LATEST_HEIGHT + 10 ))
echo "UPGRADE HEIGHT: $UPGRADE_HEIGHT"
sleep 6


cat <<EOF > "$VAL1HOME/upgrade.json" 
{
 "messages": [
  {
   "@type": "/cosmos.upgrade.v1beta1.MsgSoftwareUpgrade",
   "authority": "bitsong10d07y265gmmuvt4z0w9aw880jnsr700jktpd5u",
   "plan": {
    "name": "$UPGRADE_VERSION_TAG",
    "time": "0001-01-01T00:00:00Z",
    "height": "$UPGRADE_HEIGHT",
    "info": "https://github.com/permissionlessweb/go-bitsong/releases/download/v0.23.0-rc/bitsongd",
    "upgraded_client_state": null
   }
  }
 ],
 "metadata": "ipfs://CID",
 "deposit": "5000000000ubtsg",
 "title": "$UPGRADE_VERSION_TITLE",
 "summary": "mememe",
 "expedited": true 
}
EOF

echo "propose upgrade using expedited proposal..."
$BIND tx gov submit-proposal $VAL1HOME/upgrade.json --gas auto --gas-adjustment 1.5 --fees="2000ubtsg" --chain-id=$CHAINID --home=$VAL1HOME --from="$VAL1" -y
sleep 6

# echo "vote upgrade"
$BIND tx gov vote 1 yes --from "$DEL1" --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL1HOME -y
$BIND tx gov vote 1 yes --from "$VAL1" --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL1HOME -y
sleep 10


VAL1_OP_ADDR=$(jq -r '.body.messages[0].validator_address' $VAL1HOME/config/gentx/gentx-*.json)
echo "VAL1_OP_ADDR: $VAL1_OP_ADDR"
echo "DEL1ADDR: $DEL1ADDR"

echo "querying rewards and balances pre upgrade"


# get balances for each addr prior to upgrade
PROTOCOL_POOL_ESCROW_BALANCE_BTSG=$($BIND q bank balances "$PROTOCOL_POOL_ESCROW_ADDR" --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
PROTOCOL_POOL_BALANCE_BTSG=$($BIND q bank balances "$PROTOCOL_POOL_ADDR" --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
PROTOCOL_POOL_BALANCE_FANTOKEN=$($BIND q bank balances "$PROTOCOL_POOL_ADDR" --home $VAL1HOME --output json | jq -r ".balances[] | select(.denom == \"$FANTOKEN\") | .amount")
DISTRIBUTION_MODULE_BALANCE_BTSG=$($BIND q bank balances "$DISTRIBUTION_MODULE_ADDR" --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
DISTRIBUTION_MODULE_BALANCE_FANTOKEN=$($BIND q bank balances "$DISTRIBUTION_MODULE_ADDR" --home $VAL1HOME --output json | jq -r ".balances[] | select(.denom == \"$FANTOKEN\") | .amount")

echo "PROTOCOL_POOL_ESCROW_BALANCE_BTSG:$PROTOCOL_POOL_ESCROW_BALANCE_BTSG"
echo "PROTOCOL_POOL_BALANCE_BTSG:$PROTOCOL_POOL_BALANCE_BTSG"
echo "PROTOCOL_POOL_BALANCE_FANTOKEN:$PROTOCOL_POOL_BALANCE_FANTOKEN"
echo "DISTRIBUTION_MODULE_BALANCE_BTSG:$DISTRIBUTION_MODULE_BALANCE_BTSG"
echo "DISTRIBUTION_MODULE_BALANCE_FANTOKEN:$DISTRIBUTION_MODULE_BALANCE_FANTOKEN" # should be nothing
sleep 7



####################################################################
# C. CONFIRM
####################################################################
echo "performing v023 upgrade"
sleep 25

# # install v0.23
pkill -f $BIND
cd go-bitsong && 
git checkout v0.23.0-rc2
make install 
cd ..


# Start bitsong
echo "Running upgradehandler to fix community-pool issue..."
$BIND start --home $VAL1HOME & 
VAL1_PID=$!
echo "VAL1_PID: $VAL1_PID"
sleep 7


# get balances for each addr prior to upgrade
POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG=$($BIND q bank balances "$PROTOCOL_POOL_ADDR" --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN=$($BIND q bank balances "$PROTOCOL_POOL_ADDR" --home $VAL1HOME --output json | jq -r".balances[] | select(.denom == \"$FANTOKEN\") | .amount")
POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_BTSG=$($BIND q bank balances "$DISTRIBUTION_MODULE_ADDR" --home $VAL1HOME --output json | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_FANTOKEN=$($BIND q bank balances  "$DISTRIBUTION_MODULE_ADDR" --home $VAL1HOME --output json | jq -r ".balances[] | select(.denom == \"$FANTOKEN\") | .amount")
 

echo "PROTOCOL_POOL-BTSG:$POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG"
echo "PROTOCOL_POOL-FANTOKEN:$POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN"

## if protocol pool balances are not empty, exit 
if [ -n "$POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG" ] || [ -n "$POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN" ]; then
  echo "Protocol pool balances are not empty. Exiting..."
  exit 1
fi

echo "DISTRIBUTION-BITSONG:$POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_BTSG"
echo "DISTRIBUTION-FANTOKEN:$POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_FANTOKEN"


## protocol-pool and protocol-pool-escrow are empty balances 
if [ -n "$POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG" ] || \
   [ -n "$POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN" ]; then
  echo "Error: Both POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG and POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN should be empty" >&2
  echo "  - POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG: $POST_UPGRADE_PROTOCOL_POOL_BALANCE_BTSG" >&2
  echo "  - POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN: $POST_UPGRADE_PROTOCOL_POOL_BALANCE_FANTOKEN" >&2
  pkill -f bitsongd
  exit 1
fi

## distribution has fantoken balance now
if [ -z "$POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_FANTOKEN" ]; then
  echo "Error: POST_UPGRADE_DISTRIBUTION_MODULE_BALANCE_FANTOKEN is empty" >&2
  pkill -f bitsongd
  exit 1
fi


## community pool spend prop expedited
cat <<EOF > "$VAL1HOME/community-pool-spend.json" 
{
 "messages": [
  {
   "@type": "/cosmos.distribution.v1beta1.MsgCommunityPoolSpend",
   "authority": "bitsong10d07y265gmmuvt4z0w9aw880jnsr700jktpd5u",
   "recipient": "$USERADDR",
   "amount": [{"amount": "69420","denom":"ubtsg"}]
  }
 ],
 "metadata": "ipfs://CID",
 "deposit": "5000000000ubtsg",
 "title": "test",
 "summary": "test",
 "expedited": false
}
EOF

echo "propose upgrade using expedited proposal..."
$BIND tx gov submit-proposal $VAL1HOME/community-pool-spend.json --gas auto --gas-adjustment 1.5 --fees="2000ubtsg" --chain-id=$CHAINID --home $VAL1HOME --from=$VAL1 -y
sleep 6

# echo "vote community pool spend"
$BIND tx gov vote 2 yes --from "$DEL1" --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL1HOME -y
$BIND tx gov vote 2 yes --from "$VAL1" --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL1HOME -y
sleep 15


# ensure funds were sent to user
USER1BALANCE=$($BIND q bank balances "$USERADDR" --home $VAL1HOME -o json  | jq -r '.balances[] | select(.denom == "ubtsg") | .amount')
echo "USER1BALANCE: $USER1BALANCE"

if [ "$USER1BALANCE" != "100000000069420" ]; then
  echo "Error: USER1BALANCE is not as expected." >&2
  pkill -f bitsongd
  exit 1
fi

## calling protocol pool community pool spend errors
## using protocolpool stream errors

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

## ensure funding community pool is okay 
MSG_CODE=$($BIND tx distribution fund-community-pool $fundCommunityPool --from="$DEL1" --gas auto --fees 200ubtsg --gas-adjustment 1.2 --chain-id $CHAINID --home $VAL1HOME -o json -y | jq -r '.code')
if [ -n "$MSG_CODE" ] && [ "$MSG_CODE" -ne 0 ]; then
  exit 1
fi

echo "COMMUNITY POOL PATCH APPLIED SUCCESSFULLY, ENDING TESTS"
pkill -f bitsongd