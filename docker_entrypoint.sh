#!/bin/bash

set -e

CONFIG_FILE="/root/data/start9/config.yaml"
STATS_FILE="/root/data/start9/stats.yaml"
echo "Starting Chamberlain from config file: $CONFIG_FILE"

TOR_ADDRESS=$(yq '.tor-address' "$CONFIG_FILE")
export BITCOIND_RPC_USER=$(yq '.bitcoind-rpc-user' "$CONFIG_FILE")
export BITCOIND_RPC_PASSWORD=$(yq '.bitcoind-rpc-password' "$CONFIG_FILE")

export MINT_URL=$(yq '.mint.url' "$CONFIG_FILE")
if [ -z "$MINT_URL" ] || [ "$MINT_URL" = "null" ]; then
    export MINT_URL="http://$TOR_ADDRESS"
fi
export MINT_NAME=$(yq '.mint.name' "$CONFIG_FILE")
if [ -z "$MINT_NAME" ] || [ "$MINT_NAME" = "null" ]; then
    export MINT_NAME="Chamberlain"
fi
export MINT_DESCRIPTION=$(yq '.mint.description' "$CONFIG_FILE")
if [ -z "$MINT_DESCRIPTION" ] || [ "$MINT_DESCRIPTION" = "null" ]; then
    export MINT_DESCRIPTION="A chamberlain powered cashu mint."
fi
export MINT_MOTD=$(yq '.mint.motd' "$CONFIG_FILE")
if [ -z "$MINT_MOTD" ] || [ "$MINT_MOTD" = "null" ]; then
    export MINT_MOTD=""
fi
export MINT_CONTACT_EMAIL=$(yq '.mint.contact-info.email' "$CONFIG_FILE")
if [ -z "$MINT_CONTACT_EMAIL" ] || [ "$MINT_CONTACT_EMAIL" = "null" ]; then
    export MINT_CONTACT_EMAIL=""
fi
export MINT_CONTACT_TWITTER=$(yq '.mint.contact-info.twitter' "$CONFIG_FILE")
if [ -z "$MINT_CONTACT_TWITTER" ] || [ "$MINT_CONTACT_TWITTER" = "null" ]; then
    export MINT_CONTACT_TWITTER=""
fi
export MINT_CONTACT_NPUB=$(yq '.mint.contact-info.npub' "$CONFIG_FILE")
if [ -z "$MINT_CONTACT_NPUB" ] || [ "$MINT_CONTACT_NUB" = "null" ]; then
    export MINT_CONTACT_NPUB=""
fi

chamberlaind \
    --data-dir /root/data \
    --mint-url "$MINT_URL" \
    --mint-name "$MINT_NAME" \
    --mint-description "$MINT_DESCRIPTION" \
    --mint-motd "$MINT_MOTD" \
    --mint-contact-email "$MINT_CONTACT_EMAIL" \
    --mint-contact-twitter "$MINT_CONTACT_TWITTER" \
    --mint-contact-npub "$MINT_CONTACT_NPUB" \
    --bitcoind-rpc-url "http://bitcoind.embassy:8332" \
    --bitcoind-rpc-user "$BITCOIND_RPC_USER" \
    --bitcoind-rpc-password "$BITCOIND_RPC_PASSWORD" \
    --lightning-auto-announce=false \
    --rpc-auth-jwks-url "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_XaIPDAMB1/.well-known/jwks.json" \
    --log-level debug &

cat << EOF > "$STATS_FILE"
---
version: 2
data:
  "Mint URL":
    type: string
    value: "$MINT_URL"
    description: "The URL of the mint."
    copyable: true
    qr: false
    masked: false
EOF

SOVEREIGN_APP_ENABLED=$(yq '.sovereign-app.enabled' "$CONFIG_FILE")
echo "sovereign.app integration enabled: $SOVEREIGN_APP_ENABLED"
if [ "$SOVEREIGN_APP_ENABLED" = "true" ]; then
    # Set up sovereign.app integration
    URL="https://api.sovereign.app/clan/link"
    LINK_DETAILS_PATH="/root/data/clan_link.json"

    if [ -f "$LINK_DETAILS_PATH" ]; then
        echo "Clan link already established."
    else
        echo "Requesting link details..."
        response=$(curl -s -X POST "$URL")
        export CODE=$(echo "$response" | jq -r '.code')
        if [ -n "$CODE" ]; then
            echo "Link code retrieved: $CODE"
            yq -i '.["Link Code"] = env(CODE)' "$STATS_FILE"
        else
            echo "Failed to retrieve link code."
            exit 1
        fi
        while true; do
            rm -f "$LINK_DETAILS_PATH"
            response=$(curl -s -w "%{http_code}" -o "$LINK_DETAILS_PATH" "$URL/$CODE")
            status_code="${response: -3}"
            if [ "$status_code" -eq 200 ]; then
                echo "Link details saved to $LINK_DETAILS_PATH (restarting)"
                exit 0
            else
                echo "Link not setup (status: $status_code)"
                sleep 5  # Wait for 5 seconds before retrying
            fi
        done
    fi

    export CLAN_NAME=$(jq -r '.clan_name' "$LINK_DETAILS_PATH")
    export MINT_URL="https://$CLAN_NAME.clan.svrgn.app"
    yq -i '.mint.url = env(MINT_URL)' "$CONFIG_FILE"

    # Start FRPC
    export FRP_USER=$(jq -r '.sub' "$LINK_DETAILS_PATH")
    export FRP_PASSWORD=$(jq -r '.token' "$LINK_DETAILS_PATH")
    if [ -z "$FRP_USER" ] || [ -z "$FRP_PASSWORD" ]; then
        echo "Failed to retrieve FRP credentials."
        exit 1
    fi
    echo "Starting frpc..."
    envsubst '${CLAN_NAME} ${FRP_USER} ${FRP_PASSWORD}' < /etc/frp/frpc.toml.template > /etc/frp/frpc.toml
    frpc -c /etc/frp/frpc.toml &

    # Obtain or renew SSL certificates
    if [ ! -d "/root/data/letsencrypt/live/$CLAN_NAME.clan.svrgn.app" ]; then
        echo "Starting nginx..."
        envsubst '${CLAN_NAME}' < /etc/nginx/nginx_initial.conf.template > /etc/nginx/nginx.conf
        nginx -g "daemon off;" &
        NGINX_PID=$!
        echo "Obtaining new SSL certificate for $CLAN_NAME.clan.svrgn.app..."
        certbot certonly --nginx --non-interactive --agree-tos --email "$MINT_CONTACT_EMAIL" -d "$CLAN_NAME.clan.svrgn.app"
        kill $NGINX_PID
    else
        echo "Checking renewal status for $CLAN_NAME.clan.svrgn.app..."
        # certbot renew --cert-name "$CLAN_NAME.clan.svrgn.app" --dry-run && echo "Certificate is up to date." || {
        #     echo "Renewing SSL certificate for $CLAN_NAME.clan.svrgn.app..."
        #     certbot renew --nginx --non-interactive --agree-tos
        # }
    fi

    if [ ! -d "/root/data/letsencrypt/live/$CLAN_NAME.clanmgmt.svrgn.app" ]; then
        echo "Starting nginx..."
        envsubst '${CLAN_NAME}' < /etc/nginx/nginx_initial.conf.template > /etc/nginx/nginx.conf
        nginx -g "daemon off;" &
        NGINX_PID=$!
        echo "Obtaining new SSL certificate for $CLAN_NAME.clanmgmt.svrgn.app..."
        certbot certonly --nginx --non-interactive --agree-tos --email "$MINT_CONTACT_EMAIL" -d "$CLAN_NAME.clanmgmt.svrgn.app"
        kill $NGINX_PID
    else
        echo "Checking renewal status for $CLAN_NAME.clanmgmt.svrgn.app..."
        # certbot renew --cert-name "$CLAN_NAME.clanmgmt.svrgn.app" --dry-run && echo "Certificate is up to date." || {
        #     echo "Renewing SSL certificate for $CLAN_NAME.clanmgmt.svrgn.app..."
        #     certbot renew --nginx --non-interactive --agree-tos
        # }
    fi

    # Switch to full SSL NGINX configuration
    echo "Starting nginx with SSL configuration..."
    envsubst '${CLAN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
    nginx -g "daemon off;" &
fi

echo "Chamberlain started successfully."
wait -n
exit $?