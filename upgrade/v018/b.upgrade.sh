KEY1=$(jq -r '.name' ./test-keys/validator_seed.json)
ADDR1=$(jq -r '.address' ./test-keys/validator_seed.json)
KEY2=$(jq -r '.name' ./test-keys/relayer_seed.json)
ADDR2=$(jq -r '.address' ./test-keys/relayer_seed.json)
UPGRADE_VERSION_TAG=v18
UPGRADE_VERSION_TITLE=v0.18.0
export CHAIN_ID=localnet
export DAEMON_NAME=bitsongd
export DAEMON_HOME=$HOME/.bitsongd

$DAEMON_NAME config keyring-backend test
## Create some data
## Send
$DAEMON_NAME tx bank send $ADDR1 $ADDR2 123ubtsg --gas auto --gas-adjustment 1.2 --chain-id $CHAIN_ID -y

# sleep 6
# ## Wasm upload
# $DAEMON_NAME tx wasm upload go-bitsong/e2e/contracts/cw_template.wasm --from $KEY1 --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID -y 

# sleep 6
# ## Instantiate
# $DAEMON_NAME tx wasm i 1 '{"count":0}' --from $KEY1 --gas auto --gas-adjustment 1.3 --label="this is a test to test the test that test tests man" --no-admin  --chain-id $CHAIN_ID -y 

# sleep 6
# ### Fantoken
# $DAEMON_NAME tx fantoken issue  --name="refine" --max-supply="1234567890" --uri="ipfs://..." --from="$KEY1"  --symbol="eret" --chain-id $CHAIN_ID --fees 1000000000ubtsg -y

sleep 6
## Gov prop
$DAEMON_NAME tx gov submit-proposal software-upgrade $UPGRADE_VERSION_TAG  --title="$UPGRADE_VERSION_TITLE" --description="upgrade test"  --from="$KEY1"  --deposit 5000000000ubtsg --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID --upgrade-height 19709852 --upgrade-info https://raw.githubusercontent.com/permissionlessweb/networks/refs/heads/master/testnet/upgrades/$UPGRADE_VERSION_TITLE/cosmovisor.json -y

# Wait 1 block
sleep 6

# Vote
$DAEMON_NAME tx gov vote 42 yes  --from="$KEY1" --gas auto --gas-adjustment 1.2 -y --chain-id $CHAIN_ID


# wait till upgrade is reached
# replace version
# start network 