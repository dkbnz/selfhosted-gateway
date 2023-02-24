#!/bin/bash
# usage: create-link.sh root@gateway.selfhosted.pub selfhosted.pub nginx:80

set -e

SSH_HOST=$1
export LINK_DOMAIN=$2
export EXPOSE=$3
export WG_PRIVKEY=$(wg genkey)

# Nginx uses Docker DNS resolver for dynamic mapping of LINK_DOMAIN to link container hostnames, see nginx/*.conf
# This is the magic.
# NOTE: All traffic for `*.subdomain.domain.tld`` will be routed to the container named `subdomain-domain-tld``
# Also supports `subdomain.domain.tld` as well as apex `domain.tld`
# *.domain.tld should resolve to the Gateway's public IPv4 address
export CONTAINER_NAME=$(echo $LINK_DOMAIN | python3 -c 'fqdn=input();print("-".join(fqdn.split(".")[-3:]))')

LINK_CLIENT_WG_PUBKEY=$(echo $WG_PRIVKEY | wg pubkey)

# create gateway-link container
CONTAINER_ID=$(docker --host ssh://$SSH_HOST run --name $CONTAINER_NAME --network gateway -p 18521/udp --cap-add NET_ADMIN --restart unless-stopped -it -e LINK_CLIENT_WG_PUBKEY=$LINK_CLIENT_WG_PUBKEY -d dkbnz/shgw-link-host:latest)
# get gateway-link WireGuard pubkey 
export GATEWAY_LINK_WG_PUBKEY=$(docker --host ssh://$SSH_HOST exec $CONTAINER_NAME bash -c 'cat /etc/wireguard/link0.key | wg pubkey')
# get randomly assigned WireGuard port
export WIREGUARD_PORT=$(docker --host ssh://$SSH_HOST port $CONTAINER_NAME 18521/udp | head -n 1 | sed "s/0\.0\.0\.0://")
# get public ipv4 address
export GATEWAY_IP=$(docker --host ssh://$SSH_HOST run curlimages/curl -s 4.icanhazip.com)

cat link-compose-snippet.yml | envsubst
