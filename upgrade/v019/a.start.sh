export CHAIN_ID=sub-2
export DAEMON_NAME=bitsongd
export DAEMON_HOME=$HOME/.bitsongd


defaultCoins="100000000000ubtsg"  # 100K
nonSlashedDelegation="100000000ubtsg" # 100

# - init, config, and start the network using v018 of bitsong.
if [ -d "go-bitsong" ]; then
  # Change into the existing directory
  cd go-bitsong
  # Checkout the v0.18.1 branch
  git fetch
  # Pull the latest changes from the branch
  git pull origin v0.18.1

  make install 
else
  # Clone the repository if it doesn't exist
  git clone -b v0.18.1 https://github.com/bitsongofficial/go-bitsong
  # Change into the cloned directory
  cd go-bitsong
  make install 
fi

## download v19
git checkout hard-nett/v019-manual
make build

$DAEMON_NAME config keyring-backend test
rm -rf ../test-keys
mkdir ../test-keys

$DAEMON_NAME keys add validator --output json > ../test-keys/validator_seed.json 2>&1
sleep 1
$DAEMON_NAME keys add user --output json > ../test-keys/key_seed.json 2>&1
sleep 1
$DAEMON_NAME keys add relayer --output json > ../test-keys/relayer_seed.json 2>&1
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


# - create validator that will slash connected to other validator as peer 

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
      .app_state.slashing.params.signed_blocks_window = \"1\" |
      .app_state.slashing.params.min_signed_per_window = \"1.000000000000000000\" |
      .app_state.fantoken.params.mint_fee.denom = \"ubtsg\"" $DAEMON_HOME/config/genesis.json > tmp.json

mv tmp.json $DAEMON_HOME/config/genesis.json

# Start bitsong
$DAEMON_NAME start 