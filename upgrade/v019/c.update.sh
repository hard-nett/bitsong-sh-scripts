## get current process for bitsongd 
# start validator and grab process id of bitsongd
VAL1_PID=$(pgrep -f bitsongd)
echo "VAL1_PID: $VAL1_PID"

BIND=$1
CHAINID=$2
CHAINDIR=$3

VAL1HOME=$CHAINDIR/$CHAINID/val1
VAL2HOME=$CHAINDIR/$CHAINID/val2

UPGRADE_VERSION_TITLE="v0.20.0"
UPGRADE_VERSION_TAG="v020"
UPGRADE_INFO='{"binaries": {"linux/amd64": "https://github.com/bitsongofficial/go-bitsong/releases/download/v0.20.0/bitsongd"}}'

DEL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
DEL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
VAL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL1ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)
VAL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)

####################################################################
# UPGRADE
# kill both bitsong services & move v0.19.0 patch into go bin, simulating a manual upgrade to a version with gov support
####################################################################

# pkill -f bitsongd

# ## build v0.20.0 image in prep for upgrade 
cd go-bitsong && && git checkout v019 && make install 
cd ../ 
sleep 1

# echo "start both validators again"
bitsongd start --home $VAL1HOME &
bitsongd start --home $VAL2HOME &
echo "waiting for validators to print blocks"
sleep 6

echo "querying rewards and balances pre upgrade"
DEL1_PRE_UPGR_REWARD=$($BIND q distribution rewards $DEL1ADDR --output json  --home $VAL2HOME)
DEL2_PRE_UPGR_REWARD=$($BIND q distribution rewards $DEL2ADDR --output json --home $VAL2HOME)
DEL1_PRE_UPGR_BALANCE=$($BIND q bank balances $DEL1ADDR --home $VAL2HOME --output json)
DEL2_PRE_UPGR_BALANCE=$($BIND q bank balances $DEL2ADDR --home $VAL1HOME --output json)
# echo "DEL1_PRE_UPGR_REWARD: $DEL1_PRE_UPGR_REWARD"
# echo "DEL2_PRE_UPGR_REWARD: $DEL2_PRE_UPGR_REWARD"
# echo "DEL1_PRE_UPGR_BALANCE: $DEL1_PRE_UPGR_BALANCE"
# echo "DEL2_PRE_UPGR_BALANCE: $DEL2_PRE_UPGR_BALANCE"

LATEST_HEIGHT=$( $BIND status --home $VAL1HOME | jq -r '.SyncInfo.latest_block_height' )
UPGRADE_HEIGHT=$(( $LATEST_HEIGHT + 10 ))
# echo "$UPGRADE_HEIGHT"


# echo "propose upgrade"
$BIND tx gov submit-legacy-proposal software-upgrade v020 --upgrade-height $UPGRADE_HEIGHT --upgrade-info="$UPGRADE_INFO" --title $UPGRADE_VERSION_TITLE --description="upgrade test" --from $VAL1 --fees 1000ubtsg --deposit 5000000000ubtsg --gas auto --gas-adjustment 1.3 --no-validate --chain-id $CHAINID --home $VAL1HOME  -y
sleep 6


# echo "vote upgrade"
$BIND tx gov vote 1 yes --from $DEL1 --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL1HOME -y
$BIND tx gov vote 1 yes --from $DEL2 --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL2HOME -y
$BIND tx gov vote 1 yes --from $VAL1 --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL1HOME -y
$BIND tx gov vote 1 yes --from $VAL2 --gas auto --gas-adjustment 1.2 --fees 1000ubtsg --chain-id $CHAINID --home $VAL2HOME -y
sleep 12

# echo "wait until upgrade height is reached"
# while true; do
#   HEIGHT=$( $BIND status --home $VAL1HOME | jq -r '.SyncInfo.latest_block_height' )
#   if [ $HEIGHT -ge $UPGRADE_HEIGHT ]; then
#     echo "Target height reached, killing bitsong services..."
#     pkill -f bitsongd
#     break
#   fi
#   sleep 1
# done

# sleep 2 
# cd go-bitsong && git checkout v020 && make install

# start both validators again 
# sleep 6  
# bitsongd start --home $VAL1HOME &
# bitsongd start --home $VAL2HOME &
# sleep 6   

