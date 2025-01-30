## V21 
```
SNAPSHOT_URL=https://snapshots.polkachu.com/snapshots/bitsong/bitsong_20730391.tar.lz4

if [ ! -f "bin/*.lz4" ]; then
curl -o - -L $SNAPSHOT_URL | lz4 -c -d - | tar -x -C $VAL1HOME
else
  echo ".lz4 file found in bin directory. Skipping download."
fi

```