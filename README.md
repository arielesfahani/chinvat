## 🛡️ Chinvat (پل چینود)
## 🚀 Why Chinvat?
Chinvat is a high-performance DNS bridge relay designed to bypass DNS poisoning and protocol sabotage in high-censorship environments. Named after the mythological bridge that sifts the light from the dark, it provides a clean entry point for DNS-based tunnels like SlipNet, DNSTT, and Slipstream.

During digital blackouts, ISPs often poison public resolvers (like 8.8.8.8) or sabotage encrypted handshakes on Port 53. Chinvat solves this by:

Port Camouflage: Moves your DNS traffic from Port 53 to a stealth port (e.g., 443, 2053, or 8443) that ISPs treat as normal web traffic.

Backbone Routing: Bridges your connection through domestic data center networks (Intranet), which are rarely subjected to the same recursive poisoning as consumer lines.

Zero Dependencies: A standalone Bash script that requires no external packages (apt, yum, etc.)—essential for servers that cannot reach global update mirrors.

## 🛠️ Installation & Usage
### 1. Download & Prepare
Copy and paste this block to download the script and set the correct permissions:

Download the script from the official repository

```bash
curl -O https://raw.githubusercontent.com/arielesfahani/chinvat/main/chinvat.sh
```
Grant execution permissions

```bash
chmod +x chinvat.sh
```
### 2. Launch the Bridge
Run the script as root. You must specify a Listening Port and a Target Resolver IP.

Usage: sudo ./chinvat.sh <PORT> <RESOLVER_IP>

```bash
sudo ./chinvat.sh 443 2.188.21.20
```
### 3. Client-Side Configuration
Update your SlipNet or DNSTT client with the following parameters:

DNS Transport: UDP
DNS Resolver IP: YOUR_IRAN_VPS_IP
Resolver Port: 443 (or the port you chose)

## 🧹 Maintenance & Monitoring
### Monitor Traffic Flow
To verify that packets are being correctly relayed through the bridge, check the NAT table statistics:

View active NAT rules and packet counts

```bash
sudo iptables -t nat -L -n -v
```
### Emergency Cleanup
If you need to reset your server's network rules and remove all Chinvat configurations:

Flush all Chinvat-related NAT rules

```bash
sudo ./chinvat.sh --clean
```
## ⚠️ Critical Warnings
Cloud Firewalls: Ensure that Port 2053 (or your chosen port) is open for both UDP and TCP in your VPS provider's dashboard (e.g., ArvanCloud, or ParsPack).

Port Conflicts: If you are running x-ui or Xray, avoid using Port 443. We recommend 2053, 2083, or 8443 (if 443 is not available).

Persistence: This script is designed to be lightweight. If you reboot your server, simply re-run the launch command to restore the bridge.

## 📜 License
This project is licensed under the GNU General Public License v3.0.

Stay Connected. Crossing the bridge together.
