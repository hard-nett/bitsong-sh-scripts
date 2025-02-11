# Polytone 

This script deploys an an instance of polytone between two local chains & tests its functionality.

To reproduce the error, run this script with `v0.20.3` of go-bitsong installed:
```sh
sh a.start.sh
```

To confirm the error is resolved, run this script with `v0.20.4`  of go-bitsong installed:
```sh 
sh a.start.sh
```


*you may need to runn `pkill -f hermes` once verified polytone msgs lifecycle in logs*