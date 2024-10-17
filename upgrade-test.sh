#!/bin/bash

UPGRADE_VERSION_TAG=v0.18.0
UPGRADE_VERSION_TITLE=v0.18.0
export CHAIN_ID=sub-2
export DAEMON_NAME=bitsongd
export DAEMON_HOME=$HOME/.bitsongd
source ~/.profile

# prepare node for test
wget -q -O - https://git.io/vQhTU | bash -s -- --remove
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.22.4

## install current version 
git clone -b v0.17.0 https://github.com/permissionlessweb/go-bitsong/
cd go-bitsong && make install

## build new version to: build/$DAEMON_NAME
git checkout v0.18.0 
make build

## install cosmovisor 
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

# Setup service file
sudo tee /etc/systemd/system/$DAEMON_NAME.service > /dev/null << EOF
# setup service

[Unit]
Description=Bitsong  (cosmovisor)
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

# add upgrade to cosmovisor 
cosmovisor add-upgrade v0.18.0 build/bitsongd 

# start cosmovisor 
sudo systemctl daemon-reload
sudo systemctl enable $DAEMON_NAME.service
sudo systemctl start $DAEMON_NAME.service

sleep 10

## create some data 
## send 
$DAEMON_NAME tx bank send $KEY1 $KEY2 123ubtsg --gas auto --gas-adjustment 1.2 --chain-id $CHAIN_ID -y

sleep 3
## wasm upload 
$DAEMON_NAME tx wasm upload cw_template.wasm --from test1 --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID -y 

sleep 3
## instantiate
$DAEMON_NAME tx wasm i 1 '{}' --from test1 --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID -y 

sleep 3
### fantoken 
$DAEMON_NAME tx fantoken issue  --name="refine" --max-supply="1234567890" --uri="ipfs://..." --from test1  --chain-id test-1 --fees 1000000000ubtsg

## gov prop
$DAEMON_NAME tx gov submit-proposal software-upgrade v0.18.0   --title="v0.18.0" --description="upgrade test" --from test1  --deposit 10000000ubtsg --gas auto --gas-adjustment 1.3 --chain-id $CHAIN_ID --upgrade-height 30 --upgrade-info https://raw.githubusercontent.com/permissionlessweb/networks/refs/heads/master/testnet/upgrades/v0.18.0/cosmovisor.json -y

# wait 1 block 
sleep 3

# vote 
$DAEMON_NAME tx gov vote 1 yes --from test1 --gas auto --gas-adjustment 1.2 -y --chain-id test-1

sleep 3 
# stop  
sudo systemctl stop $DAEMON_NAME.service

# export  
$DAEMON_NAME export > pre-upgrade-export.json

# start  
sudo systemctl start $DAEMON_NAME.service

# upgrade should now be automatically run 