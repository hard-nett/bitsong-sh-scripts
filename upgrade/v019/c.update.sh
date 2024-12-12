export DAEMON_NAME=bitsongd
export DAEMON_HOME=$HOME/.bitsongd

UPGRADE_VERSION_TAG=v019
UPGRADE_VERSION_TITLE=v0.19.0
UPGRADE_HEIGHT=20
UPGRADE_INFO="https://raw.githubusercontent.com/permissionlessweb/networks/refs/heads/master/testnet/upgrades/$UPGRADE_VERSION_TITLE/cosmovisor.json -y"


VAL1=$(jq -r '.name' ./test-keys/relayer_seed.json)
VAL1ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)
VAL2=$(jq -r '.name' ./test-keys/relayer_seed.json)
VEL2ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)

DEL1=$(jq -r '.name' ./test-keys/relayer_seed.json)
DEL1ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)
DEL2=$(jq -r '.name' ./test-keys/relayer_seed.json)
DEL2ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)

sleep 6
$DAEMON_NAME q distribution reward $DEL1 

# - query balance for checking rewards have been claimed post upgrade
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