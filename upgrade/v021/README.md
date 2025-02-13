## V21

```sh
sh a.missing-slash-patch.sh
```

## B. Test upgrade logic using custom export 

### step 1: build `v0.20.6.rc`
```sh
# Clone the repository if it doesn't exist
git clone https://github.com/bitsongofficial/go-bitsong
cd go-bitsong
git checkout hard-nett/v0.20.6.rc
make install 
```
### step 2: run script
```sh
sh b.init-from-state.sh
```

