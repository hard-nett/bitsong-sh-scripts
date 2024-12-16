BIND=$1
CHAINID=$2
CHAINDIR=$3

DEL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
DEL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
VAL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL1ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)
VAL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)


VAL1HOME=$CHAINDIR/$CHAINID/val1
VAL2HOME=$CHAINDIR/$CHAINID/val2


echo "start both validators again"
bitsongd start --home $VAL1HOME &
bitsongd start --home $VAL2HOME &
echo "waiting for validators to print blocks"
sleep 6

# get balances for each addr prior to upgrade
JQ_BAL=$(| jq -r '.balances[] | select(.denom == "ubtsg") |.amount')
DEL1_PRE_UPGR_BALANCE=$($BIND q bank balances $DEL1ADDR --home $VAL2HOME --output json $JQ_BAL)
DEL2_PRE_UPGR_BALANCE=$($BIND q bank balances $DEL2ADDR --home $VAL2HOME --output json $JQ_BAL)
VAL1_PRE_UPGR_BALANCE=$($BIND q bank balances $VAL1ADDR --home $VAL1HOME --output json $JQ_BAL)
VAL2_PRE_UPGR_BALANCE=$($BIND q bank balances $VAL2ADDR --home $VAL1HOME --output json $JQ_BAL)
echo "DEL1_PRE_UPGR_BALANCE:$DEL1_PRE_UPGR_BALANCE"
echo "DEL2_PRE_UPGR_BALANCE:$DEL2_PRE_UPGR_BALANCE"
echo "VAL1_PRE_UPGR_BALANCE:$VAL1_PRE_UPGR_BALANCE"
echo "VAL2_PRE_UPGR_BALANCE:$VAL2_PRE_UPGR_BALANCE"

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

# sleep 
# cd go-bitsong && git checkout v020 && make install

# start both validators again 
# sleep 6  
# bitsongd start --home $VAL1HOME &
# bitsongd start --home $VAL2HOME &
# sleep 6   

# - check rewards & new balance
DEL1_POST_UPGR_BALANCE=$($BIND q bank balances $DEL1ADDR --home $VAL2HOME --output json $JQ_BAL)
DEL2_POST_UPGR_BALANCE=$($BIND q bank balances $DEL2ADDR --home $VAL2HOME --output json $JQ_BAL)
VAL1_POST_UPGR_BALANCE=$($BIND q bank balances $VAL1ADDR --home $VAL1HOME --output json $JQ_BAL)
VAL1_POST_UPGR_BALANCE=$($BIND q bank balances $VAL2ADDR --home $VAL1HOME --output json $JQ_BAL)


## unjail 1st validator 
$BIND tx slashing unjail --chain-id $CHAINID --home $CHAINDIR --from $VAL1 --gas auto --gas-adjustment 1.4 --fees 1000ubtsg -y 
sleep 6 

## check rewards have been redeemed
DEL1_REWARDS=$($BIND q distribution rewards $DEL1ADDR --home $VAL1HOME --output json)
DEL2_REWARDS=$($BIND q distribution rewards $DEL2ADDR --home $VAL1HOME --output json)
echo "DEL1_REWARDS:$DEL1_REWARDS"
echo "DEL2_REWARDS:$DEL2_REWARDS"
echo "VAL1_REWARDS:$VAL1_REWARDS"
echo "VAL2_REWARDS:$VAL2_REWARDS"

## get balances for each addr post upgrade
DEL1_POST_UPGR_BALANCE=$($BIND q bank balances $DEL1ADDR --home $VAL1HOME --output json)
DEL2_POST_UPGR_BALANCE=$($BIND q bank balances $DEL2ADDR --home $VAL1HOME --output json)
VAL1_POST_UPGR_BALANCE=$($BIND q bank balances $VAL1ADDR --home $VAL1HOME --output json)
VAL2_POST_UPGR_BALANCE=$($BIND q bank balances $VAL2ADDR --home $VAL1HOME --output json)
echo "DEL1_POST_UPGR_BALANCE:$DEL1_POST_UPGR_BALANCE"
echo "DEL2_POST_UPGR_BALANCE:$DEL2_POST_UPGR_BALANCE"
echo "VAL1_POST_UPGR_BALANCE:$VAL1_POST_UPGR_BALANCE"
echo "VAL2_POST_UPGR_BALANCE:$VAL2_POST_UPGR_BALANCE"

## check if rewards have been redeemed and balances updated correctly
if [ $(echo "$DEL1_REWARDS" | jq -r '.rewards[] |.reward | length') -eq 0 ] && \
   [ $(echo "$DEL1_POST_UPGR_BALANCE" | jq -r '.balances[] | select(.denom == "ubtsg") |.amount') -gt $DEL1_PRE_UPGR_BALANCE ] && \
   [ $(echo "$DEL2_POST_UPGR_BALANCE" | jq -r '.balances[] | select(.denom == "ubtsg") |.amount') -gt $DEL2_PRE_UPGR_BALANCE ]; then
    echo "Rewards have been redeemed and balances updated correctly"
else
    echo "Error: Rewards have not been redeemed or balances not updated correctly"
fi