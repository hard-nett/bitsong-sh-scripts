#!/bin/bash

# Define environment variables
export CHAIN_ID=sub-2
export DAEMON_NAME=bitsongd
export DAEMON_HOME=$HOME/.bitsongd
source ~/.profile

# Step 1: Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')

EXPECTED_VERSION="1.22.4"

if [ "$(printf '%s\n' "$GO_VERSION" "$EXPECTED_VERSION" | sort -V | head -n1)" == "$GO_VERSION" ]; then
  echo "Go version $GO_VERSION is less than the expected version $EXPECTED_VERSION. Exiting..."
  exit 1
fi
echo "Go version $GO_VERSION is already at or above the expected version $EXPECTED_VERSION. Proceeding..."

echo "Preparing node for testing..."

# Check if go-bitsong directory already exists
if [ -d "go-bitsong" ]; then
  # Change into the existing directory
  cd go-bitsong
  # Checkout the v0.17.0 branch
  git checkout v0.17.0
  # Pull the latest changes from the branch
  git pull origin v0.17.0

  make install 
else
  # Clone the repository if it doesn't exist
  git clone -b v0.17.0 https://github.com/permissionlessweb/go-bitsong
  # Change into the cloned directory
  cd go-bitsong
  make install 
fi

## Build new version to: build/$DAEMON_NAME
git checkout main
make build

## setup testnet environment 

coins="100000000000ubtsg"
delegate="100000000000ubtsg"

$DAEMON_NAME --chain-id $CHAIN_ID init $CHAIN_ID --overwrite 
sleep 1

jq ".app_state.crisis.constant_fee.denom = \"ubtsg\" |
      .app_state.staking.params.bond_denom = \"ubtsg\" |
      .app_state.mint.params.blocks_per_year = \"20000000\" |
      .app_state.merkledrop.params.creation_fee.denom = \"ubtsg\" |
      .app_state.gov.voting_params.voting_period = \"20s\" |
      .app_state.gov.deposit_params.min_deposit[0].denom = \"ubtsg\" |
      .app_state.fantoken.params.burn_fee.denom = \"ubtsg\" |
      .app_state.fantoken.params.issue_fee.denom = \"ubtsg\" |
      .app_state.fantoken.params.mint_fee.denom = \"ubtsg\"" $DAEMON_HOME/config/genesis.json > tmp.json

mv tmp.json $DAEMON_HOME/config/genesis.json

$DAEMON_NAME config keyring-backend test
rm -rf ../test-keys
mkdir ../test-keys

$DAEMON_NAME keys add validator --output json > ../test-keys/validator_seed.json 2>&1
sleep 1
$DAEMON_NAME keys add user --output json > ../test-keys/key_seed.json 2>&1
sleep 1
$DAEMON_NAME keys add relayer --output json > ../test-keys/relayer_seed.json 2>&1
sleep 1
$DAEMON_NAME add-genesis-account $($DAEMON_NAME keys show user -a) $coins
sleep 1
$DAEMON_NAME add-genesis-account $($DAEMON_NAME keys show validator -a) $coins
sleep 1
$DAEMON_NAME add-genesis-account $($DAEMON_NAME keys show relayer -a) $coins
sleep 1
$DAEMON_NAME gentx validator $delegate --chain-id $CHAIN_ID
sleep 1
$DAEMON_NAME collect-gentxs
sleep 1

echo "Change settings in config.toml and genesis.json files..."

# Start bitsong
$DAEMON_NAME start 

