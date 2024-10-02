#!/bin/bash

set -e

CONFIG_FILE="/root/data/start9/config.yaml"
echo "Starting Chamberlain from config file: $CONFIG_FILE"

BITCOIND_RPC_USER=$(yq '.bitcoind-rpc-user' "$CONFIG_FILE")
BITCOIND_RPC_PASSWORD=$(yq '.bitcoind-rpc-password' "$CONFIG_FILE")
NWS_ENABLED=$(yq '.nws.enabled' "$CONFIG_FILE")

echo "NWS enabled: $NWS_ENABLED"
if [ "$NWS_ENABLED" = "true" ]; then
    export NOSTR_RELAYS="$(yq '.nws.relay' "$CONFIG_FILE")"
    NOSTR_PRIVATE_KEY="$(yq '.nws.private-key' "$CONFIG_FILE")"
    if [ -z "$NOSTR_PRIVATE_KEY" ] || [ "$NOSTR_PRIVATE_KEY" = "null" ]; then
        echo "Generating new NOSTR private key"
        NOSTR_PRIVATE_KEY=$(openssl rand -hex 32)
        yq -i ".nws.private-key = \"$NOSTR_PRIVATE_KEY\"" "$CONFIG_FILE"
    fi
    export NOSTR_PRIVATE_KEY
    export PUBLIC="false"
    export BACKEND_HOST="localhost:3338"
fi

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

echo "Writing password to /root/data/start9/stats.yaml"
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
if [ ! -f "/root/data/auth_token" ]; then
    echo "Writing default auth token to /root/data/auth_token"
    dd if=/dev/zero of=/root/data/auth_token bs=32 count=1
fi

nws exit --port 4443 --target http://localhost:3338 &
# nginx -c /etc/nginx/nginx.conf &
chamberlaind \
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
    --lightning-auto-announce=false \
    --log-level debug &

wait -n
exit $?