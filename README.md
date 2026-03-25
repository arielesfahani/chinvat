---

## 🛡️ Chinvat (پل چینود)

A DNS bridge relay for high-censorship environments. Routes DNS tunnel traffic through Iranian datacenter backbone networks to bypass ISP-level port poisoning and resolver sabotage.

Built as the entry-point relay for [SlipNet](https://github.com/anonvector/SlipNet) and [DNSTT](https://github.com/netsec-ethz/dnstt)-based tunnels.

---

## 🚀 The Problem Chinvat Solves

During digital blackouts in Iran, ISPs enforce censorship on two layers simultaneously:

- **Port 53 is poisoned** on consumer lines — public resolvers like `8.8.8.8` and `1.1.1.1` are unreachable or return forged responses
- **Encrypted handshakes are sabotaged** — DoH and DoT traffic on port 443 or 853 is fingerprinted and dropped
- **Foreign resolvers don't respond** — E2E scanning tools (Naive Proxy, Prism, v4) return zero working results because the poisoning is at the ISP routing layer, not the resolver itself

The natural assumption is that *if resolvers don't respond, the tunnel is dead.* But the poisoning is **not uniform across all networks.** Consumer ISP lines are heavily filtered. Iranian datacenter backbone networks are not.

### Why Datacenter Networks Are Different

Iranian data centers sit on the **National Information Network (NIN) backbone**, which operates under different routing rules than consumer ISP lines. During partial or selective blackouts, this backbone retains upstream DNS access while consumer lines are cut off. This is also why Iranian resolvers served by data centers can still resolve foreign DNSTT domains (like `t.yourdomain.com`) — the NIN is selectively filtering, not in full isolation.

Chinvat exploits this gap.

---

## 🗺️ How It Works

Without Chinvat, your tunnel traffic takes the poisoned path:
```
Your Device ──► Port 53 (ISP line) ──► ✗ POISONED ──► Foreign Resolver
```

With Chinvat running on an Iranian VPS:
```
Your Device
    │
    │  DNS tunnel packets to port 443
    │  (looks like HTTPS to the ISP)
    ▼
Iranian VPS  ◄──── Chinvat intercepts here
    │
    │  DNAT: silently redirects to Iranian Resolver on port 53
    │  MASQUERADE: hides origin, traffic appears local to the VPS
    ▼
Iranian Resolver (datacenter backbone)
    │
    │  Resolves t.yourdomain.com cleanly
    ▼
DNSTT Tunnel ──► Internet
```

**Three things make this work:**

- **Port Camouflage** — Your DNS traffic moves from port 53 to a stealth port (443, 2053, or 8443) that the ISP treats as normal web traffic
- **Backbone Routing** — The VPS sits on datacenter infrastructure that is not subject to the same recursive poisoning as consumer lines
- **Zero Dependencies** — A standalone Bash script with no external packages required, essential for servers that cannot reach global update mirrors during a blackout

---

## 🛠️ Installation & Usage

### 1. Download & Prepare
```bash
# Download the script from the official repository
curl -O https://raw.githubusercontent.com/arielesfahani/chinvat/main/chinvat.sh
```
```bash
# Grant execution permissions
chmod +x chinvat.sh
```

### 2. Launch the Bridge

Run the script as root. Specify a Listening Port and a Target Resolver IP.
```
Usage: sudo ./chinvat.sh <PORT> <RESOLVER_IP>
```
```bash
sudo ./chinvat.sh 443 2.188.21.20
```

Chinvat will create an isolated `CHINVAT` chain in iptables, apply DNAT and MASQUERADE rules for the specified port, and save the configuration automatically to `/etc/iptables/rules.v4`.

### 3. Multi-Bridge Mode

You can run multiple bridges simultaneously — different ports pointing to different resolvers — without affecting existing rules. Each invocation only modifies rules for the port you specify:
```bash
sudo ./chinvat.sh 443 2.188.21.20
sudo ./chinvat.sh 2053 10.10.10.5
sudo ./chinvat.sh 8443 185.55.225.25
```

All bridges remain active in parallel. To see all running bridges:
```bash
sudo iptables -t nat -L CHINVAT -n -v
```

### 4. Client-Side Configuration

Update your SlipNet or DNSTT client with the following parameters:

| Parameter       | Value                           |
|-----------------|---------------------------------|
| DNS Transport   | UDP                             |
| DNS Resolver IP | `YOUR_IRAN_VPS_IP`              |
| Resolver Port   | `443` *(or the port you chose)* |

---

## 🧹 Maintenance & Monitoring

### Monitor Traffic Flow

Chinvat uses an isolated chain, so you can monitor your DNS bridge traffic without noise from the rest of the server:
```bash
# View only Chinvat-specific traffic and packet counts
sudo iptables -t nat -L CHINVAT -n -v
```

### Emergency Cleanup

To remove all Chinvat bridges and reset the NAT rules:
```bash
sudo ./chinvat.sh --clean
```

---

## ⚠️ Critical Warnings

> **Cloud Firewalls:** Ensure that your chosen port is open for both UDP and TCP in your VPS provider's firewall dashboard (e.g., ArvanCloud, ParsPack). The iptables rules alone are not enough if the provider-level firewall blocks the port upstream.

> **Port Conflicts:** If you are running x-ui or Xray on the same server, avoid port 443. Use 2053, 2083, or 8443 instead.

> **Persistence:** Chinvat saves rules to `/etc/iptables/rules.v4` on every run. If `iptables-persistent` is installed on your server, bridges will survive reboots automatically. Otherwise, re-run the launch command after a reboot.

> **Resolver Selection:** During active blackouts, foreign resolvers (8.8.8.8, 1.1.1.1) will not respond even from a VPS. Use Iranian resolvers served by datacenter infrastructure. If you are unsure whether a resolver is working, the fact that your DNSTT domain resolves at all confirms the NIN is in selective — not total — isolation mode.

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0**.

---

*Stay Connected. Crossing the bridge together.*
