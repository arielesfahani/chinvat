#!/bin/bash

# =================================================================
# Project: CHINVAT (پل چینود)
# Description: DNS Bridge Relay for High-Censorship Environments
# Version: 1.3 (Isolated Chain Edition)
# =================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Run as root (sudo).${NC}"
   exit 1
fi

# Cleanup function
cleanup_all() {
    echo -e "${RED}[!] Tearing down the Chinvat Bridge...${NC}"
    # Remove the jump rule from PREROUTING
    iptables -t nat -D PREROUTING -j CHINVAT 2>/dev/null
    # Flush and delete the custom chain
    iptables -t nat -F CHINVAT 2>/dev/null
    iptables -t nat -X CHINVAT 2>/dev/null
    # Flush POSTROUTING for a clean slate
    iptables -t nat -F POSTROUTING 2>/dev/null
    echo "Done. All rules cleared."
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

echo -e "${GREEN}[*] Raising the Chinvat Bridge...${NC}"

# 1. Enable Forwarding
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 2. Create/Reset the CHINVAT Chain
# This ensures we NEVER have duplicate or old rules.
iptables -t nat -N CHINVAT 2>/dev/null
iptables -t nat -F CHINVAT
iptables -t nat -F POSTROUTING

# 3. Ensure PREROUTING jumps to our CHINVAT chain
# We use -C to check if the jump rule exists, if not, we add it.
iptables -t nat -C PREROUTING -j CHINVAT 2>/dev/null || iptables -t nat -I PREROUTING 1 -j CHINVAT

# 4. Apply the Relay Rules to the CHINVAT Chain
iptables -t nat -A CHINVAT -p udp --dport "$PORT" -j DNAT --to-destination "$RESOLVER":53
iptables -t nat -A CHINVAT -p tcp --dport "$PORT" -j DNAT --to-destination "$RESOLVER":53

# 5. Apply Masquerade
iptables -t nat -A POSTROUTING -p udp -d "$RESOLVER" --dport 53 -j MASQUERADE
iptables -t nat -A POSTROUTING -p tcp -d "$RESOLVER" --dport 53 -j MASQUERADE

# 6. Open Traffic in Forward Table
iptables -I FORWARD -p udp --dport 53 -j ACCEPT
iptables -I FORWARD -p tcp --dport 53 -j ACCEPT
iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# 7. Persistence
mkdir -p /etc/iptables/
iptables-save > /etc/iptables/rules.v4

echo -e "${GREEN}====================================================${NC}"
echo -e "CHINVAT IS ACTIVE: Port $PORT -> $RESOLVER"
echo -e "Check status with: ${GREEN}sudo iptables -t nat -L CHINVAT -n -v${NC}"
echo -e "====================================================${NC}"
