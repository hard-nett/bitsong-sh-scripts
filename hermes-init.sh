#!/bin/bash

rm -rf ~/.hermes

mkdir -p ~/.hermes
cp hermes.toml ~/.hermes/config.toml

echo "Validate hermes config file"
hermes config validate

echo "Clean up hermes"
hermes keys delete --chain "test-1" --all
hermes keys delete --chain "test-2" --all

echo "Importing keys"
hermes keys add --key-name relayer_key_test_1 --chain "test-1" --hd-path "m/44'/639'/0'/0/0" --mnemonic-file <(jq -r '.mnemonic' ./data/test-1/relayer_seed.json)
hermes keys add --key-name relayer_key_test_2 --chain "test-2" --hd-path "m/44'/639'/0'/0/0" --mnemonic-file <(jq -r '.mnemonic' ./data/test-2/relayer_seed.json)
#sleep 2
#echo "Creating IBC transfer channel"
#hermes create channel --a-chain $CHAIN_1 --a-connection $SRC_IBC_CONNECTION --a-port wasm.$NOTE_CONTRACT --b-port wasm.$VOICE_CONTRACT --channel-version polytone-1
hermes create channel --a-chain test-1 --a-port transfer --b-chain test-2 --b-port transfer --new-client-connection

#hermes --config hermes.toml start