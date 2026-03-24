#!/bin/bash

# =================================================================
# Project: CHINVAT (پل چینود)
# Description: DNS Bridge Relay for High-Censorship Environments
# License: GNU GPL v3.0
# =================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

show_help() {
    echo -e "${GREEN}CHINVAT - The Bridge of Judgment (DNS Relay)${NC}"
    echo "Usage: sudo ./chinvat.sh <PORT> <RESOLVER_IP>"
    echo "Options:"
    echo "  --clean    Remove all Chinvat iptables rules and reset NAT"
    echo ""
    echo "Example: sudo ./chinvat.sh 2053 2.188.21.20"
}

cleanup_rules() {
    echo -e "${RED}[!] Crossing back: Flushing NAT table...${NC}"
    iptables -t nat -F
    iptables -t nat -X
    echo "Done. Rules cleared."
    exit 0
}

if [[ "$1" == "--clean" ]]; then
    cleanup_rules
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Run as root (sudo).${NC}"
   exit 1
fi

if [ "$#" -ne 2 ]; then
    show_help
    exit 1
fi

PORT=$1
RESOLVER=$2

echo -e "${GREEN}[*] Raising the Chinvat Bridge...${NC}"

# Enable Forwarding
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# Apply NAT Rules
iptables -t nat -A PREROUTING -p udp --dport "$PORT" -j DNAT --to-destination "$RESOLVER":53
iptables -t nat -A PREROUTING -p tcp --dport "$PORT" -j DNAT --to-destination "$RESOLVER":53
iptables -t nat -A POSTROUTING -p udp -d "$RESOLVER" --dport 53 -j MASQUERADE
iptables -t nat -A POSTROUTING -p tcp -d "$RESOLVER" --dport 53 -j MASQUERADE

# Open Traffic
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# Persistence (Manual Save)
mkdir -p /etc/iptables/
iptables-save > /etc/iptables/rules.v4

echo -e "${GREEN}====================================================${NC}"
echo -e "CHINVAT IS WIDE: Port $PORT -> $RESOLVER"
echo -e "====================================================${NC}"
