#!/bin/bash

# owner key name in keyring
KEY1=
# owner address of key1
ADDR1=
# empty balance addr
ADDR2=

# Define environment variables
UPGRADE_VERSION_TAG=v0.18.0
UPGRADE_VERSION_TITLE=v0.18.0
export CHAIN_ID=sub-2
export DAEMON_NAME=bitsongd
export DAEMON_HOME=$HOME/.bitsongd
source ~/.profile

# Prepare node for test
wget -q -O - https://git.io/vQhTU | bash -s -- --remove
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.22.4

## Install current version
git clone -b v0.17.0 https://github.com/permissionlessweb/go-bitsong/
cd go-bitsong && make install

## Build new version to: build/$DAEMON_NAME
git checkout $UPGRADE_VERSION_TAG
make build

## Install cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

# Setup service file
sudo tee /etc/systemd/system/$DAEMON_NAME.service > /dev/null << EOF
# setup service

[Unit]
Description=Bitsong (cosmovisor)
After=network-online.target

[Service]
User=root
ExecStart=$HOME/go/bin/cosmovisor run start
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=$DAEMON_NAME"
Environment="DAEMON_HOME=$DAEMON_HOME"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"

[Install]
WantedBy=multi-user.target
EOF

# v1 cosmovisor
cosmovisor init $HOME/go/bin/$DAEMON_NAME

# Add upgrade to cosmovisor
cosmovisor add-upgrade $UPGRADE_VERSION_TAG build/$DAEMON_NAME


## setup testnet environment 

coins="100000000000ubtsg"
delegate="100000000000ubtsg"

$DAEMON_NAME --chain-id $CHAIN_ID init $CHAIN_ID
sleep 1

jq ".app_state.crisis.constant_fee.denom = \"ubtsg\" |
      .app_state.staking.params.bond_denom = \"ubtsg\" |
      .app_state.merkledrop.params.creation_fee.denom = \"ubtsg\" |
      .app_state.gov.deposit_params.min_deposit[0].denom = \"ubtsg\" |
      .app_state.fantoken.params.burn_fee.denom = \"ubtsg\" |
      .app_state.fantoken.params.issue_fee.denom = \"ubtsg\" |
      .app_state.fantoken.params.mint_fee.denom = \"ubtsg\"" $CHAINDIR/$CHAIN_ID/config/genesis.json > tmp.json

mv tmp.json $CHAINDIR/$CHAIN_ID/config/genesis.json

$DAEMON_NAME keys add validator $KEYRING --output json > validator_seed.json 2>&1
sleep 1
$DAEMON_NAME keys add user $KEYRING --output json > key_seed.json 2>&1
sleep 1
$DAEMON_NAME keys add relayer $KEYRING --output json > relayer_seed.json 2>&1
sleep 1
$DAEMON_NAME add-genesis-account $($DAEMON_NAME keys $KEYRING show user -a) $coins
sleep 1
$DAEMON_NAME add-genesis-account $($DAEMON_NAME keys $KEYRING show validator -a) $coins
sleep 1
$DAEMON_NAME add-genesis-account $($DAEMON_NAME keys $KEYRING show relayer -a) $coins
sleep 1
$DAEMON_NAME gentx validator $delegate $KEYRING --chain-id $CHAIN_ID
sleep 1
$DAEMON_NAME gentx validator $delegate $KEYRING --chain-id $CHAIN_ID
sleep 1
$DAEMON_NAME collect-gentxs
sleep 1

echo "Change settings in config.toml and genesis.json files..."
sed -i 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:'"$RPCPORT"'"#g' $CHAINDIR/$CHAIN_ID/config/config.toml
sed -i 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT"'"#g' $CHAINDIR/$CHAIN_ID/config/config.toml
sed -i 's#"localhost:6060"#"localhost:'"$PROFPORT"'"#g' $CHAINDIR/$CHAIN_ID/config/config.toml
sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $CHAINDIR/$CHAIN_ID/config/config.toml
sed -i 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $CHAINDIR/$CHAIN_ID/config/config.toml
sed -i 's/index_all_keys = false/index_all_keys = true/g' $CHAINDIR/$CHAIN_ID/config/config.toml
#sed -i 's/enable = false/enable = true/g' $CHAINDIR/$CHAIN_ID/config/app.toml
#sed -i 's/swagger = false/swagger = true/g' $CHAINDIR/$CHAIN_ID/config/app.toml
sed -i 's/"voting_period": "172800s"/"voting_period": "120s"/g' $CHAINDIR/$CHAIN_ID/config/genesis.json
sed -i 's/"stake"/"ubtsg"/g' $CHAINDIR/$CHAIN_ID/config/genesis.json

# Start cosmovisor
sudo systemctl daemon-reload
sudo systemctl enable $DAEMON_NAME.service
sudo systemctl start $DAEMON_NAME.service

sleep 10

## Create some data
## Send
$DAEMON_NAME tx bank send $ADDR1 $KEY2 123ubtsg --gas auto --gas-adjustment 1.2 --chain-id $CHAIN_ID -y

sleep 3
## Wasm upload
$DAEMON_NAME tx wasm upload cw_template.wasm --from test1 --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID -y 

sleep 3
## Instantiate
$DAEMON_NAME tx wasm i 1 '{}' --from test1 --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID -y 

sleep 3
### Fantoken
$DAEMON_NAME tx fantoken issue  --name="refine" --max-supply="1234567890" --uri="ipfs://..." --from test1  --chain-id $CHAIN_ID --fees 1000000000ubtsg

## Gov prop
$DAEMON_NAME tx gov submit-proposal software-upgrade $UPGRADE_VERSION_TAG   --title="$UPGRADE_VERSION_TITLE" --description="upgrade test" --from test1  --deposit 10000000ubtsg --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID --upgrade-height 30 --upgrade-info https://raw.githubusercontent.com/permissionlessweb/networks/refs/heads/master/testnet/upgrades/$UPGRADE_VERSION_TAG/cosmovisor.json -y

# Wait 1 block
sleep 3

# Vote
$DAEMON_NAME tx gov vote 1 yes --from test1 --gas auto --gas-adjustment 1.2 -y --chain-id $CHAIN_ID

sleep 3 
# Stop
sudo systemctl stop $DAEMON_NAME.service

# Export
$DAEMON_NAME export > pre-upgrade-export.json

# Start
sudo systemctl start $DAEMON_NAME.service

# Upgrade should now be automatically run
