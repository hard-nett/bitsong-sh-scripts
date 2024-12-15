
# - upgrade to new version 
UPGRADE_HEIGHT=

VAL1=$(jq -r '.name' ./test-keys/relayer_seed.json)
VAL1ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)
VAL2=$(jq -r '.name' ./test-keys/relayer_seed.json)
VEL2ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)

DEL1=$(jq -r '.name' ./test-keys/relayer_seed.json)
DEL1ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)
DEL2=$(jq -r '.name' ./test-keys/relayer_seed.json)
DEL2ADDR=$(jq -r '.address' ./test-keys/relayer_seed.json)

# - check rewards & new balance
$DAEMON_NAME q bank balances $DEL1
$DAEMON_NAME q bank balances $DEL2
$DAEMON_NAME q distribution reward $DEL1

# - confirm slashing events are registered by slashing again 
$DAEMON_NAME status # 
$DAEMON_NAME q distribution slashes $DEL1 1

# confirm deleagtor 1 rewards can be queried 
# confirm delegator 1 rewards were calculated and claimed correctly 