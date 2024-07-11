#!/bin/sh

set -e

CONFIG_FILE="/root/data/start9/config.yaml"

BITCOIND_RPC_USER=$(yq '.bitcoind-rpc-user' "$CONFIG_FILE")
BITCOIND_RPC_PASSWORD=$(yq '.bitcoind-rpc-password' "$CONFIG_FILE")
MINT_URL=$(yq '.mint-url' "$CONFIG_FILE")
MINT_NAME=$(yq '.mint-name' "$CONFIG_FILE")
if [ -z "$MINT_NAME" ] || [ "$MINT_NAME" = "null" ]; then
    MINT_NAME="Chamberlain"
fi
MINT_DESCRIPTION=$(yq '.mint-description' "$CONFIG_FILE")
if [ -z "$MINT_DESCRIPTION" ] || [ "$MINT_DESCRIPTION" = "null" ]; then
    MINT_DESCRIPTION="A chamberlain powered cashu mint."
fi
MINT_CONTACT_EMAIL=$(yq '.contact-info.email' "$CONFIG_FILE")
if [ -z "$MINT_CONTACT_EMAIL" ] || [ "$MINT_CONTACT_EMAIL" = "null" ]; then
    MINT_CONTACT_EMAIL=""
fi
MINT_CONTACT_TWITTER=$(yq '.contact-info.twitter' "$CONFIG_FILE")
if [ -z "$MINT_CONTACT_TWITTER" ] || [ "$MINT_CONTACT_TWITTER" = "null" ]; then
    MINT_CONTACT_TWITTER=""
fi
MINT_CONTACT_NPUB=$(yq '.contact-info.npub' "$CONFIG_FILE")
if [ -z "$MINT_CONTACT_NPUB" ] || [ "$MINT_CONTACT_NUB" = "null" ]; then
    MINT_CONTACT_NPUB=""
fi
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
    --data-dir /root/data \
    --mint-url "$MINT_URL" \
    --mint-name "$MINT_NAME" \
    --mint-description "$MINT_DESCRIPTION" \
    --mint-contact-email "$MINT_CONTACT_EMAIL" \
    --mint-contact-twitter "$MINT_CONTACT_TWITTER" \
    --mint-contact-npub "$MINT_CONTACT_NPUB" \
    --password "$PASSWORD" \
    --bitcoind-rpc-url "http://bitcoind.embassy:8332" \
    --bitcoind-rpc-user "$BITCOIND_RPC_USER" \
    --bitcoind-rpc-password "$BITCOIND_RPC_PASSWORD" \
    --http-host 0.0.0.0 \
    --rpc-host 0.0.0.0 \
    --lightning-auto-announce=false \
    --log-level debug
