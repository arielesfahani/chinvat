#!/bin/bash

# =================================================================
# Project: CHINVAT (پل چینود)
# Description: DNS Bridge Relay for High-Censorship Environments
# Version: 1.4 (Multi-Bridge Edition)
# =================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Run as root (sudo).${NC}"
   exit 1
fi

cleanup_all() {
    echo -e "${RED}[!] Tearing down ALL Chinvat Bridges...${NC}"
    iptables -t nat -D PREROUTING -j CHINVAT 2>/dev/null
    iptables -t nat -F CHINVAT 2>/dev/null
    iptables -t nat -X CHINVAT 2>/dev/null
    iptables -t nat -F POSTROUTING 2>/dev/null
    echo "Done. All bridges cleared."
    exit 0
}

if [[ "$1" == "--clean" ]]; then
    cleanup_all
fi

if [ "$#" -ne 2 ]; then
    echo -e "${GREEN}Usage:${NC} sudo ./chinvat.sh <PORT> <RESOLVER_IP>"
    exit 1
fi

PORT=$1
RESOLVER=$2

echo -e "${GREEN}[*] Updating Chinvat Bridge on Port $PORT...${NC}"

# 1. Enable Forwarding
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 2. Ensure the CHINVAT Chain exists and is linked
iptables -t nat -N CHINVAT 2>/dev/null
iptables -t nat -C PREROUTING -j CHINVAT 2>/dev/null || iptables -t nat -I PREROUTING 1 -j CHINVAT

# 3. PORT-SPECIFIC CLEANUP
# This removes ONLY the rules for the port you are currently configuring.
# It loops to ensure any duplicates are gone.
echo -e "[*] Removing old rules for port $PORT..."
while iptables -t nat -D CHINVAT -p udp --dport "$PORT" -j DNAT 2>/dev/null; do :; done
while iptables -t nat -D CHINVAT -p tcp --dport "$PORT" -j DNAT 2>/dev/null; do :; done

# Clean up Masquerade for this specific resolver to prevent clutter
iptables -t nat -D POSTROUTING -p udp -d "$RESOLVER" --dport 53 -j MASQUERADE 2>/dev/null
iptables -t nat -D POSTROUTING -p tcp -d "$RESOLVER" --dport 53 -j MASQUERADE 2>/dev/null

# 4. Apply New Rules for this Port
iptables -t nat -A CHINVAT -p udp --dport "$PORT" -j DNAT --to-destination "$RESOLVER":53
iptables -t nat -A CHINVAT -p tcp --dport "$PORT" -j DNAT --to-destination "$RESOLVER":53

# 5. Apply Masquerade for the Resolver
iptables -t nat -A POSTROUTING -p udp -d "$RESOLVER" --dport 53 -j MASQUERADE
iptables -t nat -A POSTROUTING -p tcp -d "$RESOLVER" --dport 53 -j MASQUERADE

# 6. Forwarding rules (General)
iptables -I FORWARD -p udp --dport 53 -j ACCEPT 2>/dev/null
iptables -I FORWARD -p tcp --dport 53 -j ACCEPT 2>/dev/null

# 7. Persistence
mkdir -p /etc/iptables/
iptables-save > /etc/iptables/rules.v4

echo -e "${GREEN}====================================================${NC}"
echo -e "CHINVAT UPDATED: Port ${GREEN}$PORT${NC} is now bridged to ${GREEN}$RESOLVER${NC}"
echo -e "Your other bridges remain active."
echo -e "Check all bridges: ${GREEN}sudo iptables -t nat -L CHINVAT -n -v${NC}"
echo -e "====================================================${NC}"
