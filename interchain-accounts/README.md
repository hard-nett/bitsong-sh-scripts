# Interchain Bitsong Abstract Accounts

## Usage

This project supports two deployment scenarios:

### With AuthZ (Currently broken. Issue tracked [here](https://github.com/AbstractSDK/abstract/issues/569))
```bash
# Run deployment with AuthZ grants
sh a.deploy.sh --enable-authz
```

### Without AuthZ (works as expected)
```bash
# Run deployment without AuthZ grants
sh a.deploy.sh --disable-authz
```

## Manual Rust Scripts

You can also run the Rust scripts directly:

### With AuthZ
```bash
cd ibaa-scripts && cargo run --bin init_contracts -- --authz-granter <GRANTER_ADDRESS>
cd ibaa-scripts && cargo run --bin full_deploy -- --authz-granter <GRANTER_ADDRESS>
```

### Without AuthZ
```bash
cd ibaa-scripts && cargo run --bin init_contracts
cd ibaa-scripts && cargo run --bin full_deploy
```