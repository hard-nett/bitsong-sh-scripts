
BIND=bitsongd
CHAINID_A=test-1
CHAINID_B=test-2

# file paths
CHAINDIR=./data
VAL1AHOME=$CHAINDIR/$CHAINID_A/val1
VAL1BHOME=$CHAINDIR/$CHAINID_B/val1
HERMES=~/.hermes
DEL1FILE="test-keys/delegator1_seed.json"
DEL2FILE="test-keys/delegator2_seed.json"
VAL1AFILE="test-keys/validator1a_seed.json"
VAL1BFILE="test-keys/validator1b_seed.json"
RELAYERFILE="test-keys/relayer_seed.json"
USERFILE="test-keys/key_seed.json"
POLYTONE_CONTRACTS=(
  "polytone_listener.wasm"
  "polytone_note.wasm"
  "polytone_proxy.wasm"
  "polytone_voice.wasm"
  "polytone_tester.wasm"
  )

# Define the new ports for val1 on chain a
VAL1A_API_PORT=1317
VAL1A_GRPC_PORT=9090
VAL1A_GRPC_WEB_PORT=9091
VAL1A_PROXY_APP_PORT=26658
VAL1A_RPC_PORT=26657
VAL1A_PPROF_PORT=6060
VAL1A_P2P_PORT=26656

# Define the new ports for val1 on chain b
VAL1B_API_PORT=1318
VAL1B_GRPC_PORT=10090
VAL1B_GRPC_WEB_PORT=10091
VAL1B_PROXY_APP_PORT=9395
VAL1B_RPC_PORT=27657
VAL1B_PPROF_PORT=6361
VAL1B_P2P_PORT=26356



echo "Creating $BINARY instance for VAL1_A: home=$VAL1AHOME | chain-id=$CHAINID_A | p2p=:$VAL1A_P2P_PORT | rpc=:$VAL1A_RPC_PORT | profiling=:$VAL1A_PPROF_PORT | grpc=:$VAL1A_GRPC_PORT"
echo "Creating $BINARY instance for VAL1_B: home=$VAL1BHOME | chain-id=$CHAINID_B | p2p=:$VAL1B_P2P_PORT | rpc=:$VAL1B_RPC_PORT | profiling=:$VAL1B_PPROF_PORT | grpc=:$VAL1B_GRPC_PORT"

defaultCoins="100000000000ubtsg"  # 100K
delegate="1000000ubtsg" # 1btsg

####################################################################
# A. CHAINS CONFIG
####################################################################

rm -rf $VAL1AHOME $VAL1BHOME 
# - init, config, and start the network using v018 of bitsong.
if [ -d "go-bitsong" ]; then
  # Change into the existing directory
  cd go-bitsong
  # Checkout the v0.18.1 branch
  git fetch
  # Pull the latest changes from the branch
  git pull origin v0.20.3
  make install 
else
  # Clone the repository if it doesn't exist
  git clone https://github.com/bitsongofficial/go-bitsong
  # Change into the cloned directory
  cd go-bitsong
  make install 
fi

cd ..

rm -rf $VAL1AHOME/test-keys
rm -rf $VAL1BHOME/test-keys


$BIND init $CHAINID_A --overwrite --home $VAL1AHOME --chain-id $CHAINID_A
sleep 1
$BIND init $CHAINID_B --overwrite --home $VAL1BHOME --chain-id $CHAINID_B
sleep 1


mkdir $VAL1AHOME/test-keys
mkdir $VAL1BHOME/test-keys


$BIND --home $VAL1AHOME config keyring-backend test
$BIND --home $VAL1BHOME config keyring-backend test
sleep 1
$BIND --home $VAL1AHOME config chain-id $CHAINID_A
$BIND --home $VAL1BHOME config chain-id $CHAINID_B
sleep 1

# optimize val1 genesis for testing
jq ".app_state.crisis.constant_fee.denom = \"ubtsg\" |
      .app_state.staking.params.bond_denom = \"ubtsg\" |
      .app_state.mint.params.blocks_per_year = \"20000000\" |
      .app_state.mint.params.mint_denom = \"ubtsg\" |
      .app_state.merkledrop.params.creation_fee.denom = \"ubtsg\" |
      .app_state.gov.voting_params.voting_period = \"15s\" |
      .app_state.gov.params.voting_period = \"15s\" |
      .app_state.gov.params.min_deposit[0].denom = \"ubtsg\" |
      .app_state.fantoken.params.burn_fee.denom = \"ubtsg\" |
      .app_state.fantoken.params.issue_fee.denom = \"ubtsg\" |
      .app_state.slashing.params.signed_blocks_window = \"10\" |
      .app_state.slashing.params.min_signed_per_window = \"0.500000000000000000\" |
      .app_state.fantoken.params.mint_fee.denom = \"ubtsg\"" $VAL1AHOME/config/genesis.json > $VAL1AHOME/config/tmp.json
# give val2 genesis optimized genesis
mv $VAL1AHOME/config/tmp.json $VAL1AHOME/config/genesis.json
cp $VAL1AHOME/config/genesis.json $VAL1BHOME/config/genesis.json
jq ".chain_id = \"$CHAINID_B\"" $VAL1BHOME/config/genesis.json > $VAL1BHOME/config/tmp.json
mv $VAL1BHOME/config/tmp.json $VAL1BHOME/config/genesis.json

# setup test keys.
VAL1A=val1
VAL1B=val1
RELAYER=relayer
DEL1=del
DEL2=del
USER=user

yes | $BIND  --home $VAL1AHOME keys add $VAL1A --output json > $VAL1AHOME/$VAL1AFILE 2>&1 
sleep 1
yes | $BIND  --home $VAL1AHOME keys add $USER --output json > $VAL1AHOME/$USERFILE 2>&1
sleep 1
yes | $BIND  --home $VAL1BHOME keys add $USER --output json > $VAL1BHOME/$USERFILE 2>&1
sleep 1
yes | $BIND  --home $VAL1AHOME keys add $RELAYER --output json > $VAL1AHOME/$RELAYERFILE 2>&1
sleep 1
yes | $BIND  --home $VAL1AHOME keys add $DEL1 --output json > $VAL1AHOME/$DEL1FILE 2>&1
sleep 1
yes | $BIND  --home $VAL1BHOME keys add $VAL1B --output json > $VAL1BHOME/$VAL1BFILE 2>&1
sleep 1
yes | $BIND  --home $VAL1BHOME keys add $DEL2  --output json > $VAL1BHOME/$DEL2FILE 2>&1
sleep 1

RELAYERADDR=$(jq -r '.address' $CHAINDIR/$CHAINID_A/val1/$RELAYERFILE)
DEL1ADDR=$(jq -r '.address' $CHAINDIR/$CHAINID_A/val1/$DEL1FILE)
DEL2ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID_B/val1/$DEL2FILE)
VAL1A_ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID_A/val1/$VAL1AFILE)
VAL1B_ADDR=$(jq -r '.address'  $CHAINDIR/$CHAINID_B/val1/$VAL1BFILE)
USERAADDR=$(jq -r '.address' $CHAINDIR/$CHAINID_A/val1/$USERFILE)

$BIND --home $VAL1AHOME genesis add-genesis-account $USERAADDR $defaultCoins
sleep 1
$BIND --home $VAL1AHOME genesis add-genesis-account $RELAYERADDR $defaultCoins
sleep 1
$BIND --home $VAL1AHOME genesis add-genesis-account $VAL1A_ADDR $defaultCoins
sleep 1
$BIND --home $VAL1AHOME genesis add-genesis-account $DEL1ADDR $defaultCoins
sleep 1
$BIND --home $VAL1AHOME genesis add-genesis-account $DEL2ADDR $defaultCoins
sleep 1
$BIND --home $VAL1AHOME genesis gentx $VAL1A $delegate --chain-id $CHAINID_A
sleep 1
$BIND genesis collect-gentxs --home $VAL1AHOME
sleep 1

# setup second chain 
$BIND genesis add-genesis-account $USER $defaultCoins --home $VAL1BHOME 
sleep 1
$BIND genesis add-genesis-account $VAL1B_ADDR $defaultCoins --home $VAL1BHOME 
sleep 1
$BIND genesis add-genesis-account $RELAYERADDR $defaultCoins --home $VAL1BHOME 
sleep 1
$BIND genesis gentx $VAL1B $delegate --home $VAL1BHOME --chain-id $CHAINID_B
sleep 1
$BIND genesis collect-gentxs --home $VAL1BHOME 

VAL1A_P2P_ADDR=$($BIND tendermint show-node-id --home $VAL1AHOME)@localhost:$VAL1A_P2P_PORT

# app & config modiifications
# config.toml
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL1A_PROXY_APP_PORT\"/g" $VAL1AHOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL1A_RPC_PORT\"/" $VAL1AHOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL1A_RPC_PORT\"/" $VAL1AHOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL1A_P2P_PORT\"/" $VAL1AHOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL1AHOME/config/config.toml &&
sed -i.bak -e "s/^pprof_laddr *=.*/pprof_laddr = \"localhost:6060\"/g" $VAL1AHOME/config/config.toml &&
# val2
sed -i.bak -e "s/^proxy_app *=.*/proxy_app = \"tcp:\/\/127.0.0.1:$VAL1B_PROXY_APP_PORT\"/g" $VAL1BHOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/127.0.0.1:$VAL1B_RPC_PORT\"/" $VAL1BHOME/config/config.toml &&
sed -i.bak "/^\[rpc\]/,/^\[/ s/address.*/address = \"tcp:\/\/127.0.0.1:$VAL1B_RPC_PORT\"/" $VAL1BHOME/config/config.toml &&
sed -i.bak "/^\[p2p\]/,/^\[/ s/laddr.*/laddr = \"tcp:\/\/0.0.0.0:$VAL1B_P2P_PORT\"/" $VAL1BHOME/config/config.toml &&
sed -i.bak -e "s/^grpc_laddr *=.*/grpc_laddr = \"\"/g" $VAL1BHOME/config/config.toml &&
sed -i.bak -e "s/^pprof_laddr *=.*/pprof_laddr = \"localhost:6070\"/g" $VAL1BHOME/config/config.toml &&
# app.toml
sed -i.bak "/^\[api\]/,/^\[/ s/minimum-gas-prices.*/minimum-gas-prices = \"0.0ubtsg\"/" $VAL1AHOME/config/app.toml &&
sed -i.bak "/^\[api\]/,/^\[/ s/address.*/address = \"tcp:\/\/0.0.0.0:$VAL1A_API_PORT\"/" $VAL1AHOME/config/app.toml &&
sed -i.bak "/^\[grpc\]/,/^\[/ s/address.*/address = \"localhost:$VAL1A_GRPC_PORT\"/" $VAL1AHOME/config/app.toml &&
sed -i.bak "/^\[grpc-web\]/,/^\[/ s/address.*/address = \"localhost:$VAL1A_GRPC_WEB_PORT\"/" $VAL1AHOME/config/app.toml &&
# val2
sed -i.bak "/^\[api\]/,/^\[/ s/minimum-gas-prices.*/minimum-gas-prices = \"0.0ubtsg\"/" $VAL1BHOME/config/app.toml &&
sed -i.bak "/^\[api\]/,/^\[/ s/address.*/address = \"tcp:\/\/0.0.0.0:$VAL1B_API_PORT\"/" $VAL1BHOME/config/app.toml &&
sed -i.bak "/^\[grpc\]/,/^\[/ s/address.*/address = \"localhost:$VAL1B_GRPC_PORT\"/" $VAL1BHOME/config/app.toml &&
sed -i.bak "/^\[grpc-web\]/,/^\[/ s/address.*/address = \"localhost:$VAL1B_GRPC_WEB_PORT\"/" $VAL1BHOME/config/app.toml &&


# Start chains
echo "Starting chain 1..."
$BIND start --home $VAL1AHOME & 
VAL1A_PID=$!
echo "VAL1A_PID: $VAL1A_PID"
sleep 1

echo "Starting chain 2..."
$BIND start --home $VAL1BHOME & 
VAL1B_PID=$!
echo "VAL1B_PID: $VAL1B_PID"

sleep 1
####################################################################
# B. RELAYER CONFIG
####################################################################
## create mnemonic file, grab menmonic from relayer key file, print to new txt file

REL_MNEMONIC=$(jq -r '.mnemonic' $VAL1AHOME/$RELAYERFILE)
echo "$REL_MNEMONIC" >  $VAL1AHOME/mnemonic.txt
## if hermes command does not exist, install hermes
if ! command -v hermes &> /dev/null
then
    cargo install ibc-relayer-cli --bin hermes --locked
else

## configure hermes with chain & and b
rm -rf $HERMES && mkdir -p $HERMES
cp ../pfm/hermes.toml $HERMES/config.toml

## modify $HERMES_CFG toml with correct values 
sed -i.bak "/^\[chains\]/,/^\[/ { 
    /id = \"$CHAINID_A\"/ { 
        s/rpc_addr.*/rpc_addr = \"http:\/\/127.0.0.1:$VAL1A_RPC_PORT\"/; 
        s/grpc_addr.*/grpc_addr = \"http:\/\/127.0.0.1:$VAL1A_GRPC_PORT\"/; 
        s/event_source.url.*/event_source.url = \"ws:\/\/127.0.0.1:$VAL1A_RPC_PORT\/websocket\"/; 
        s/key_name.*/key_name = \"$VAL1\"/; 
    } 
}" "$HERMES/config.toml"

sed -i.bak "/^\[chains\]/,/^\[/ { 
    /id = \"$CHAINID_B\"/ { 
        s/rpc_addr.*/rpc_addr = \"http:\/\/127.0.0.1:$VAL1B_RPC_PORT\"/; 
        s/grpc_addr.*/grpc_addr = \"http:\/\/127.0.0.1:$VAL1B_GRPC_PORT\"/; 
        s/event_source.url.*/event_source.url = \"ws:\/\/127.0.0.1:$VAL1B_RPC_PORT\/websocket\"/; 
        s/key_name.*/key_name = \"$VAL2\"/; 
    } 
}" "$HERMES/config.toml"


echo "Clean up hermes"
hermes keys delete --chain "$CHAINID_A" --all
hermes keys delete --chain "$CHAINID_B" --all

# import keys 
hermes keys add --key-name $RELAYER --chain $CHAINID_A --hd-path "m/44'/639'/0'/0/0" --mnemonic-file $VAL1AHOME/mnemonic.txt
hermes keys add --key-name $RELAYER --chain $CHAINID_B --hd-path "m/44'/639'/0'/0/0" --mnemonic-file $VAL1AHOME/mnemonic.txt

## start relayer 
sleep 15
echo "Creating IBC transfer channel"
hermes create channel --a-chain $CHAINID_A --b-chain $CHAINID_B --a-port transfer --b-port transfer --new-client-connection --yes
# hermes create channel --a-chain $CHAINID_A --b-chain $CHAINID_B --a-port transfer --b-port transfer --new-client-connection --yes
# wait until new channel is created
sleep 30

## if polytone wasm files dont exist in  ./bin, download 
if [ -z "$(ls -A ./bin)" ]; then
  sh download.sh
  while [ -z "$(ls -A ./bin)" ]; do
    sleep 1
  done
fi


## upload polytone 
for CHAIN in $VAL1AHOME $VAL1BHOME; do
  echo "Uploading polytone WASM files for $CHAIN..."
  for contract in "${POLYTONE_CONTRACTS[@]}"; do
    echo "Uploading $contract WASM file..."
    # get tx hash 
    $BIND tx wasm upload ./bin/$contract --from $USER --gas auto --gas-adjustment 1.4 --gas auto --fees 400000ubtsg -y --home $CHAIN
    sleep 1
    echo "Uploaded $contract WASM file successfully."
    # get code id from tx hash  
  done
  echo "Finished uploading polytone WASM files for $CHAIN."
done
fi

####################################################################
# C. POLYTONE CONFIG
####################################################################
POLYONE_NOTE_ID=2
POLYONE_VOICE_ID=4
POLYONE_PROXY_ID=3
POLYONE_TESTER_ID=5

# init note
 $BIND tx wasm i $POLYONE_NOTE_ID '{"block_max_gas": 100_000_000 }' --from $USER --home $VAL1AHOME --no-admin --label="note contract chain1" -y --fees 400000ubtsg --gas auto --gas-adjustment 1.3
 $BIND tx wasm i $POLYONE_NOTE_ID '{"block_max_gas": 100_000_000 }' --from $USER --home $VAL1BHOME --no-admin --label="note contract chain2" -y --fees 400000ubtsg --gas auto --gas-adjustment 1.3
# init voice
 $BIND tx wasm i $POLYONE_VOICE_ID '{"proxy_code_id":$POLYONE_PROXY_ID,"block_max_gas":100_000_000, "contract_addr_len":32}'  --from $USER --home $VAL1AHOME -y --fees 400000ubtsg --gas auto --gas-adjustment 1.3
 $BIND tx wasm i $POLYONE_VOICE_ID '{"proxy_code_id":$POLYONE_PROXY_ID,"block_max_gas":100_000_000, "contract_addr_len":32}'  --from $USER --home $VAL2AHOME -y --fees 400000ubtsg --gas auto --gas-adjustment 1.3

# init tester
 $BIND tx wasm i $POLYONE_TESTER_ID '{}' --from $USER --home $VAL1AHOME --no-admin --label="tester contract chain1" -y 
 $BIND tx wasm i $POLYONE_TESTER_ID '{}' --from $USER --home $VAL1BHOME --no-admin --label="tester contract chain2" -y 

sleep 6
POLYONE_PROXY_ADDR_A=$($BIND q wasm lca $POLYONE_PROXY_ID --home $VAL1AHOME -o json | jq -r .contracts[0])
POLYONE_NOTE_ADDR_A=$($BIND q wasm lca $POLYONE_NOTE_ID  --home $VAL1AHOME -o json | jq -r .contracts[0])
POLYONE_TESTER_ADDR_A=$($BIND q wasm lca $POLYONE_TESTER_ID --home $VAL1AHOME -o json | jq -r .contracts[0])
POLYONE_PROXY_ADDR_B=$($BIND q wasm lca $POLYONE_PROXY_ID --home $VAL1BHOME -o json | jq -r .contracts[0])
POLYONE_NOTE_ADDR_B=$($BIND q wasm lca $POLYONE_NOTE_ID  --home $VAL1BHOME -o json | jq -r .contracts[0])
POLYONE_TESTER_ADDR_B=$($BIND q wasm lca $POLYONE_TESTER_ID --home $VAL1BHOME -o json | jq -r .contracts[0])

## create channel 
hermes create channel --a-chain $CHAINID_A -b-chain $CHAINID_B\
    --a-port "wasm.$POLYONE_NOTE_ADDR_A"\
    --b-port "wasm.$POLYONE_NOTE_ADDR_B"\
    --order unordered\
    --version polytone-1

# wait for channel to be created
sleep 60

####################################################################
# C. POLYTONE INTEGRATION
####################################################################

# send msg to note
 $BIND tx wasm e $POLYONE_NOTE_ADDR_A '{"execute":{"msgs":[],"timeout_seconds":100,"callback": {"receiver": "$POLYONE_TESTER_ADDR", "msg":"aGVsbG8K"}}}'

# wait for packet to relay.
sleep 60

# query callback history for test contract 
$BIND q wasm contract-state smart $POLYONE_NOTE_ADDR_A '{"history":{}}' -o json

## history should exist, and the callback initiator should equal the test addr
