DAEMON_NAME=$1
CHAINID=$2
CHAINDIR=$3

VAL1HOME=$CHAINDIR/$CHAINID/val1
VAL2HOME=$CHAINDIR/$CHAINID/val2

UPGRADE_VERSION_TAG=v019
UPGRADE_VERSION_TITLE=v0.19.0
UPGRADE_HEIGHT=20
UPGRADE_INFO="https://raw.githubusercontent.com/permissionlessweb/networks/refs/heads/master/testnet/upgrades/$UPGRADE_VERSION_TITLE/cosmovisor.json -y"


VAL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL1ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)
VAL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)

DEL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
DEL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)


# kill bitsong service 
pkill -f bitsongd 

# install v019 manually
git checkout -b v0.19.0-patch &&
make install && 

sleep 6
# start both nodes again 
bitsongd start --home $VAL1HOME &
bitsongd start --home $VAL2HOME &

# - query balance for checking rewards have been claimed post upgrade
$DAEMON_NAME q distribution reward $DEL1 
$DAEMON_NAME q bank balances $DEL1 
$DAEMON_NAME q bank balances $DEL2

# - propose upgrade 
$DAEMON_NAME tx gov submit-proposal software-upgrade $UPGRADE_VERSION_TAG  --title="$UPGRADE_VERSION_TITLE" --description="upgrade test"  --from="$VAL1"  --deposit 5000000000ubtsg --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID --upgrade-height $UPGRADE_HEIGHT --upgrade-info $UPGRADE_INFO
sleep 6

# - vote upgrade 
$DAEMON_NAME tx gov vote 1 yes  --from="$DEL1" --gas auto --gas-adjustment 1.2 -y --chain-id $CHAIN_ID
$DAEMON_NAME tx gov vote 1 yes  --from="$DEL2" --gas auto --gas-adjustment 1.2 -y --chain-id $CHAIN_ID
$DAEMON_NAME tx gov vote 1 yes  --from="$VAL1" --gas auto --gas-adjustment 1.2 -y --chain-id $CHAIN_ID
$DAEMON_NAME tx gov vote 1 yes  --from="$VAL2" --gas auto --gas-adjustment 1.2 -y --chain-id $CHAIN_ID


# wait until we get to upgrade height 
while true; do
  RESPONSE=$( $DAEMON_NAME q status )
  BLOCK_HEIGHT=$( echo "$RESPONSE" | jq -r '.SyncInfo.latest_block_height' )
  echo "Current block height: $BLOCK_HEIGHT"
  if [ $BLOCK_HEIGHT -ge $UPGRADE_HEIGHT ]; then
    echo "Upgrade height reached!"
    break
  fi
  sleep 6
done

## move new binary into go bin folder 
BIN_PATH=$(which $DAEMON_NAME)
mv go-bitsong/bin/bitsongd $BIN_PATH
$UPGRADE_HEIGHT

#  kill daemon 10 seconds after we reach upgrade height
sleep 10
pkill -f bitsongd
sleep 4
$DAEMON_NAME start