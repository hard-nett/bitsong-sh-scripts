#!/bin/bash

# PFM Test:
# https://hermes.informal.systems/documentation/forwarding/test.html

# Send tokens
hermes tx ft-transfer \
 --timeout-seconds 10000 \
 --dst-chain test-2 \
 --src-chain test-1 \
 --src-port transfer \
 --src-channel channel-0 \
 --amount 1000 \
 --denom ubtsg

hermes tx ft-transfer \
 --denom ubtsg \
 --receiver cosmos1jwr34yvnkqkc0ddndnh9y8t94hlhn7rapfyags \
 --memo '{"forward": {"receiver": "cosmos1al3csagycya3l7ze3dk4345czw9vwgtjtsezut", "port": "transfer", "channel": "channel-1"}}' \
 --timeout-seconds 120 \
 --dst-chain ibc-1 \
 --src-chain ibc-0 \
 --src-port transfer \
 --src-channel channel-0 \
 --amount 2500