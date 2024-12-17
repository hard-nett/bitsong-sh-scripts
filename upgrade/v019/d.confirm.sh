BIND=bitsongd
CHAINID=test-1
CHAINDIR=./data

DEL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/$CHAINID/val1/test-keys/delegator1_seed.json)
DEL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
DEL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/delegator2_seed.json)
VAL1=$(jq -r '.name' $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL1ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val1/test-keys/validator1_seed.json)
VAL2=$(jq -r '.name'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)
VAL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID/val2/test-keys/validator2_seed.json)


# start val1 first, not enough vp to start blocks, used to query and set this scripts variables
VAL1HOME=$CHAINDIR/$CHAINID/val1
VAL2HOME=$CHAINDIR/$CHAINID/val2
echo "start val1, query data"
bitsongd start --home $VAL1HOME &

sleep 6

VAL1_OP_ADDR=$(jq -r '.body.messages[0].validator_address' $VAL1HOME/config/gentx/gentx-*.json)
VAL2_OP_ADDR=$($BIND q staking validators --home $VAL1HOME -o json | jq -r ".validators[] | select(.operator_address!= \"$VAL1_OP_ADDR\") |.operator_address" | head -1)

echo "VAL1_OP_ADDR: $VAL1_OP_ADDR"
echo "VAL2_OP_ADDR: $VAL2_OP_ADDR"
echo "DEL1ADDR: $DEL1ADDR"
echo "DEL2ADDR: $DEL2ADDR"

# query delegations
VAL1_DEL1_SHARES=$($BIND q staking delegation $DEL1ADDR $VAL1_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegation.shares' )
VAL1_DEL1_BTSG=$($BIND q staking delegation $DEL1ADDR $VAL1_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegation.balance.amount' )
VAL2_DEL2_SHARES=$($BIND q staking delegation $DEL2ADDR $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegation.shares')
VAL2_DEL2_BTSG=$($BIND q staking delegation $DEL2ADDR $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegation.balance.amount')
VAL2_DEL1_SHARES=$($BIND q staking delegation $DEL1ADDR $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegation.shares')
VAL2_DEL1_BTSG=$($BIND q staking delegation $DEL1ADDR $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegation.balance.amount')

VAL1_TOTAL_SHARES=$($BIND q staking validator $VAL1_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegator_shares')
VAL1_TOTAL_TOKENS=$($BIND q staking validator $VAL1_OP_ADDR --home $VAL1HOME -o json | jq -r '.tokens')
VAL_COMMISSION="0.10"
VAL2_TOTAL_SHARES=$($BIND q staking validator $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.delegator_shares')
VAL2_TOTAL_TOKENS=$($BIND q staking validator $VAL2_OP_ADDR --home $VAL1HOME -o json | jq -r '.tokens')
sleep 6

echo "VAL1_DEL1_SHARES: $VAL1_DEL1_SHARES"
echo "VAL1_DEL1_BTSG: $VAL1_DEL1_BTSG"
echo "VAL2_DEL2_SHARES: $VAL2_DEL2_SHARES"
echo "VAL2_DEL2_BTSG: $VAL2_DEL2_BTSG"
echo "VAL2_DEL1_SHARES: $VAL2_DEL1_SHARES"
echo "VAL2_DEL1_BTSG: $VAL2_DEL1_BTSG"

echo "VAL1_TOTAL_SHARES: $VAL1_TOTAL_SHARES"
echo "VAL1_TOTAL_TOKENS: $VAL1_TOTAL_TOKENS"
echo "VAL2_TOTAL_SHARES: $VAL2_TOTAL_SHARES"
echo "VAL2_TOTAL_TOKENS: $VAL2_TOTAL_TOKENS"
sleep 1

# val2 gets 2x rewards each block than val1
# validator info for calc rewards
## val1 now has: 
##  - total staked: 200btsg staked
## - total vp: 
## val2 now has: 
##  - total staked: 400btsg staked
## - total vp: 
## rewards minted per block: TBD
## del1 -> val1 starting info: 
## - block height: 
## - power: 
## del2 -> val2
## - block height: 
## - power: 
## del1 -> val2
## 3899ubtsg per block
## 148200 ubtsg

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

bitsongd start --home $VAL2HOME &
echo "waiting for validators to print blocks"
sleep 10

echo "check rewards & new balance"
DEL1_POST_UPGR_BALANCE=$($BIND q bank balances $DEL1ADDR --home $VAL2HOME --output json $JQ_BAL)
DEL2_POST_UPGR_BALANCE=$($BIND q bank balances $DEL2ADDR --home $VAL2HOME --output json $JQ_BAL)
VAL1_POST_UPGR_BALANCE=$($BIND q bank balances $VAL1ADDR --home $VAL1HOME --output json $JQ_BAL)
VAL1_POST_UPGR_BALANCE=$($BIND q bank balances $VAL2ADDR --home $VAL1HOME --output json $JQ_BAL)


echo "check rewards have been redeemed"
DEL1_REWARDS=$($BIND q distribution rewards $DEL1ADDR --home $VAL1HOME --output json)
DEL2_REWARDS=$($BIND q distribution rewards $DEL2ADDR --home $VAL1HOME --output json)
echo "DEL1_REWARDS:$DEL1_REWARDS"
echo "DEL2_REWARDS:$DEL2_REWARDS"
echo "VAL1_REWARDS:$VAL1_REWARDS"
echo "VAL2_REWARDS:$VAL2_REWARDS"
sleep 1


echo "unjail 1st validator"
$BIND tx slashing unjail --chain-id $CHAINID --home $CHAINDIR --from $VAL1 --home $VAL1HOME --gas auto --gas-adjustment 1.4 --fees 1000ubtsg -y 
sleep 6 

## get balances for each addr post upgrade
DEL1_POST_UPGR_BALANCE=$($BIND q bank balances $DEL1ADDR --home $VAL1HOME --output json)
DEL2_POST_UPGR_BALANCE=$($BIND q bank balances $DEL2ADDR --home $VAL1HOME --output json)
VAL1_POST_UPGR_BALANCE=$($BIND q bank balances $VAL1ADDR --home $VAL1HOME --output json)
VAL2_POST_UPGR_BALANCE=$($BIND q bank balances $VAL2ADDR --home $VAL1HOME --output json)
echo "DEL1_POST_UPGR_BALANCE:$DEL1_POST_UPGR_BALANCE"
echo "DEL2_POST_UPGR_BALANCE:$DEL2_POST_UPGR_BALANCE"
echo "VAL1_POST_UPGR_BALANCE:$VAL1_POST_UPGR_BALANCE"
echo "VAL2_POST_UPGR_BALANCE:$VAL2_POST_UPGR_BALANCE"
sleep 1

## subtract post upgrade from pre upgrade to view the amount of tokens redeemed by the delegations
DEL1_REDEEMED=$(echo $(echo "$DEL1_PRE_UPGR_BALANCE" - $(echo "$DEL1_POST_UPGR_BALANCE" | jq -r '.balances[] | select(.denom == "ubtsg") |.amount')) | bc)
DEL2_REDEEMED=$(echo $(echo "$DEL2_PRE_UPGR_BALANCE" - $(echo "$DEL2_POST_UPGR_BALANCE" | jq -r '.balances[] | select(.denom == "ubtsg") |.amount')) | bc)

if [ $(echo "$DEL1_REWARDS" | jq -r '.rewards[] |.reward | length') -eq 0 ] && \
   [ $DEL1_REDEEMED -gt 0 ] && \
   [ $DEL2_REDEEMED -gt 0 ]; then
    echo "Rewards have been redeemed and balances updated correctly"
    echo "Delegation 1 redeemed: $DEL1_REDEEMED ubtsg"
    echo "Delegation 2 redeemed: $DEL2_REDEEMED ubtsg"
else
    echo "Error: Rewards have not been redeemed or balances not updated correctly"
fi