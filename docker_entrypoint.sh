#!/bin/sh

set -e

CONFIG_FILE="/root/data/start9/config.yaml"

BITCOIND_RPC_USER=$(yq '.bitcoind-rpc-user' "$CONFIG_FILE")
BITCOIND_RPC_PASSWORD=$(yq '.bitcoind-rpc-password' "$CONFIG_FILE")
MINT_URL=$(yq '.mint-url' "$CONFIG_FILE")
PASSWORD=$(tr -dc a-km-zA-HJ-NP-Z2-9 </dev/urandom | head -c 8)

cat << EOF > /root/data/start9/stats.yaml
---
version: 2
data:
  Password:
    type: string
    value: "$PASSWORD"
    description: Auth token password.
    copyable: true
    qr: false
    masked: true
EOF

exec tini -p SIGTERM chamberlaind -- \
    --mint-url $MINT_URL \
    --password $PASSWORD \
    --bitcoind-rpc-url http://bitcoind.embassy:8332 \
    --bitcoind-rpc-user $BITCOIND_RPC_USER \
    --bitcoind-rpc-password $BITCOIND_RPC_PASSWORD \
    --http-host 0.0.0.0 \
    --rpc-host 0.0.0.0 \
    --log-level debug
