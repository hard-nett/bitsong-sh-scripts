export DAEMON_NAME=bitsongd
export DAEMON_HOME=$HOME/.bitsongd
## move new binary into go bin folder 
BIN_PATH=$(which $DAEMON_NAME)
mv go-bitsong/bin/bitsongd $BIN_PATH

## set min gas price in app.toml 
awk '/minimum-gas-prices = ""/ { print "minimum-gas-prices = \"0.025ubtsg\""; next } { print }' $DAEMON_HOME/config/app.toml > $DAEMON_HOME/config/app.toml.new
mv $DAEMON_HOME/config/app.toml.new $DAEMON_HOME/config/app.toml

## start new binary 
$DAEMON_NAME start