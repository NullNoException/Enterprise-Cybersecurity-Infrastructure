# OPNsense Firewall Setup Guide

Complete guide for deploying OPNsense firewall with Terraform on VirtualBox to implement the 5-network architecture from [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md).

## Overview

OPNsense is an open-source firewall/router that will serve as the central security gateway for all network traffic in the CyberLab infrastructure.

### Network Architecture

```
                    ┌─────────────────────┐
                    │   OPNsense VM       │
                    │  (Central Router)   │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │          │           │           │          │
        │          │           │           │          │
    ┌───▼───┐  ┌──▼───┐  ┌────▼────┐  ┌──▼──┐  ┌────▼─────┐
    │  WAN  │  │ DMZ  │  │Internal │  │ Sec │  │Management│
    │  NAT  │  │vbox1 │  │ vbox2   │  │vbox3│  │  vbox4   │
    └───────┘  └──────┘  └─────────┘  └─────┘  └──────────┘
    Internet   172.25   172.25.20    172.25   172.25.40
               .10.0/24   .0/24      .30.0/24   .0/24
```

### Network Segments

| Network | Subnet | Interface | Purpose |
|---------|--------|-----------|---------|
| **WAN** | NAT | em0 | Internet connectivity |
| **DMZ** | 172.25.10.0/24 | em1 | Public services (NGINX, T-Pot) |
| **Internal** | 172.25.20.0/24 | em2 | Protected services (DB, LDAP) |
| **Security** | 172.25.30.0/24 | em3 | Monitoring (Wazuh, ELK) |
| **Management** | 172.25.40.0/24 | em4 | Admin interfaces (Grafana) |

## Prerequisites

### 1. VirtualBox Installation

```bash
# macOS
brew install --cask virtualbox

# Verify installation
VBoxManage --version
```

### 2. Download OPNsense ISO

**Option A: Use the automated script (Recommended)**
```bash
cd terraform/scripts
./download-opnsense.sh

# Downloads OPNsense 24.1 (latest stable)
# Decompresses automatically
# Places in terraform/iso/ directory
```

**Option B: Manual download**
```bash
# Create ISO directory
mkdir -p terraform/iso
cd terraform/iso

# Download ISO (choose one mirror)
curl -L -O https://mirror.ams1.nl.leaseweb.net/opnsense/releases/24.1/OPNsense-24.1-dvd-amd64.iso.bz2

# Decompress
bunzip2 OPNsense-24.1-dvd-amd64.iso.bz2
```

**ISO Information:**
- Size: ~650MB compressed, ~900MB uncompressed
- Version: 24.1 (January 2024 release)
- Architecture: AMD64 (x86_64)

### 3. VirtualBox Network Setup

The Terraform configuration will automatically create the required host-only networks:

```bash
# These are created automatically by terraform
vboxnet0 → 172.25.0.0/24 (External)
vboxnet1 → 172.25.10.0/24 (DMZ)
vboxnet2 → 172.25.20.0/24 (Internal)
vboxnet3 → 172.25.30.0/24 (Security)
vboxnet4 → 172.25.40.0/24 (Management)
```

**Manual creation (if needed):**
```bash
# Create networks manually
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet1 --ip 172.25.10.1 --netmask 255.255.255.0

# Repeat for vboxnet2, vboxnet3, vboxnet4
```

## Terraform Deployment

### Step 1: Configure Variables

Edit `terraform.tfvars`:

```hcl
# Enable architecture deployment
deploy_architecture = true
deploy_opnsense     = true

# Platform settings
platform   = "darwin"  # or "linux"
hypervisor = "virtualbox"

# OPNsense configuration
opnsense_cpus   = 2
opnsense_memory = 2048  # 2GB recommended minimum

# Network subnets (use defaults from ARCHITECTURE.md)
arch_external_subnet   = "172.25.0.0/24"
arch_dmz_subnet        = "172.25.10.0/24"
arch_internal_subnet   = "172.25.20.0/24"
arch_security_subnet   = "172.25.30.0/24"
arch_management_subnet = "172.25.40.0/24"

# ISO location (adjust if different)
iso_path      = "./iso"
opnsense_iso  = "OPNsense-24.1-dvd-amd64.iso"
```

### Step 2: Initialize and Deploy

```bash
cd terraform

# Initialize Terraform
terraform init

# Preview deployment
terraform plan

# Deploy OPNsense
terraform apply

# Confirm with 'yes' when prompted
```

**Deployment time:** 2-5 minutes

### Step 3: Verify Deployment

```bash
# Check VM is running
VBoxManage list runningvms

# Should show:
# "cyberlab-opnsense" {<uuid>}

# View VM details
terraform output opnsense_info
```

## OPNsense Initial Configuration

### 1. Console Access

```bash
# Access VM console
VBoxManage startvm cyberlab-opnsense --type gui

# Or headless mode
VBoxManage startvm cyberlab-opnsense --type headless

# Connect via VNC or web console
```

### 2. Initial Boot Configuration

OPNsense will boot and present a configuration wizard:

1. **Installer Selection**: Choose "Install (UFS)"
2. **Keyboard Layout**: Select your layout (e.g., us)
3. **Partitioning**: Select "Auto (UFS)" - use entire disk
4. **Installation**: Wait for installation to complete (~5 minutes)
5. **Reboot**: Remove ISO and reboot

### 3. Interface Assignment

After reboot, you'll see the console menu:

```
*** Welcome to OPNsense 24.1 ***

Available interfaces:
em0: <WAN>
em1: <LAN>
em2: <OPT1>
em3: <OPT2>
em4: <OPT3>

Select option: 1) Assign interfaces
```

**Interface assignment:**
1. Select option `1` (Assign interfaces)
2. Configure as follows:
   - WAN interface: `em0`
   - LAN interface: `em4` (Management network)
   - Optional interfaces:
     - OPT1: `em1` (DMZ)
     - OPT2: `em2` (Internal)
     - OPT3: `em3` (Security)
3. Save configuration

### 4. Set Interface IP Addresses

**Option 2: Set interface IP address**

Configure each interface:

**LAN (Management) - em4:**
```
IPv4 address: 172.25.40.1
Subnet mask: 24
Enable DHCP: No
```

**OPT1 (DMZ) - em1:**
```
IPv4 address: 172.25.10.1
Subnet mask: 24
Enable DHCP: Yes (range: 172.25.10.100-172.25.10.200)
```

**OPT2 (Internal) - em2:**
```
IPv4 address: 172.25.20.1
Subnet mask: 24
Enable DHCP: Yes (range: 172.25.20.100-172.25.20.200)
```

**OPT3 (Security) - em3:**
```
IPv4 address: 172.25.30.1
Subnet mask: 24
Enable DHCP: Yes (range: 172.25.30.100-172.25.30.200)
```

## Web UI Access

### 1. Initial Access

From your host machine:

```
URL: https://172.25.40.1
Username: root
Password: opnsense
```

**First-time setup wizard will appear**

### 2. Initial Setup Wizard

1. **General Information**
   - Hostname: `opnsense`
   - Domain: `cyberlab.local`
   - DNS Servers: `8.8.8.8, 1.1.1.1`

2. **Time Zone**
   - Select your timezone

3. **WAN Interface**
   - Type: DHCP (or Static if needed)
   - RFC1918 Networks: Block private networks on WAN

4. **LAN Interface**
   - IP: 172.25.40.1/24 (already configured)

5. **Root Password**
   - **CHANGE IMMEDIATELY**
   - Use a strong password
   - Store securely

6. **Finish**
   - Click "Reload" to apply configuration

## Firewall Rules Configuration

### 1. Interface Naming

**System > Settings > Interface**

Rename interfaces for clarity:
- OPT1 → `DMZ`
- OPT2 → `INTERNAL`
- OPT3 → `SECURITY`

### 2. Default Firewall Rules

**Firewall > Rules**

#### DMZ Rules (172.25.10.0/24)

Allow inbound for public services:
```
Action: Pass
Interface: DMZ
Protocol: TCP
Source: Any
Destination: DMZ net
Destination Port: 80, 443 (HTTP/HTTPS)
Description: Allow web traffic to NGINX
```

```
Action: Pass
Interface: DMZ
Protocol: Any
Source: DMZ net
Destination: INTERNAL net
Description: Allow DMZ to Internal backend
```

#### Internal Rules (172.25.20.0/24)

```
Action: Pass
Interface: INTERNAL
Protocol: Any
Source: INTERNAL net
Destination: SECURITY net
Description: Allow logs to Security network
```

```
Action: Block
Interface: INTERNAL
Protocol: Any
Source: INTERNAL net
Destination: WAN net
Description: Block direct Internet access
```

#### Security Rules (172.25.30.0/24)

```
Action: Pass
Interface: SECURITY
Protocol: Any
Source: SECURITY net
Destination: Any
Description: Allow Security network (monitoring)
```

#### Management Rules (172.25.40.0/24)

```
Action: Pass
Interface: MANAGEMENT
Protocol: TCP
Source: MANAGEMENT net
Destination: Any
Destination Port: 443
Description: Allow admin HTTPS access
```

### 3. NAT Configuration

**Firewall > NAT > Outbound**

- Mode: Automatic outbound NAT
- This allows internal networks to access internet via WAN

### 4. Port Forwarding (Optional)

**Firewall > NAT > Port Forward**

Example: Forward external HTTPS to NGINX:
```
Interface: WAN
Protocol: TCP
Destination: WAN address
Destination Port: 443
Redirect Target IP: 172.25.10.10 (NGINX)
Redirect Target Port: 443
Description: HTTPS to NGINX
```

## IDS/IPS Configuration

### Enable Suricata

**Services > Intrusion Detection**

1. **Settings**
   - Enable IDS: ✓
   - IPS Mode: ✓ (if desired)
   - Interfaces: Select all (DMZ, INTERNAL, SECURITY, MANAGEMENT)
   - Pattern matcher: Hyperscan
   - Promiscuous mode: ✓

2. **Download Rules**
   - Go to: **Download** tab
   - Click: "Download & Update Rules"
   - Wait for completion (~5 minutes)

3. **Enable Rulesets**
   - ET Open rules
   - Abuse.ch rules
   - Enable categories: web, malware, trojan, exploit

4. **Start Service**
   - Click "Apply" to start Suricata

## VPN Configuration (WireGuard)

### 1. Enable WireGuard

**VPN > WireGuard**

1. **Enable WireGuard**: ✓
2. **Create Instance**
   - Name: `wg0`
   - Listen Port: `51820`
   - Tunnel Address: `10.100.0.1/24`
   - Generate keypair

3. **Create Peers**
   - Add peer for each remote user
   - Generate keypairs
   - Allowed IPs: `10.100.0.0/24, 172.25.0.0/16`

### 2. Firewall Rules for VPN

Add rule on WAN:
```
Action: Pass
Interface: WAN
Protocol: UDP
Destination Port: 51820
Description: Allow WireGuard VPN
```

## Logging Configuration

### 1. Enable Remote Logging

**System > Settings > Logging**

1. **Remote Logging**
   - Enable: ✓
   - Target: `172.25.30.30` (Logstash)
   - Port: `5514`
   - Protocol: UDP
   - Facility: Local0

2. **Log Level**
   - Set to "Informational" or higher

### 2. Log Rotation

- Max file size: 500 KB
- Log files: 7
- Compression: ✓

## Monitoring Integration

### 1. SNMP Configuration

**Services > SNMP**

```
Enable: ✓
Interface: MANAGEMENT
Community: public
Location: CyberLab
Contact: admin@cyberlab.local
```

### 2. Prometheus Exporter

**Services > Prometheus**

```
Enable: ✓
Listen Address: 172.25.40.1
Port: 9100
```

Add to Prometheus scrape config:
```yaml
- job_name: 'opnsense'
  static_configs:
    - targets: ['172.25.40.1:9100']
```

## Backup Configuration

### 1. Manual Backup

**System > Configuration > Backups**

- Click "Download configuration"
- Save XML file securely
- Store offsite

### 2. Automated Backup

**System > Configuration > Backups > Settings**

```
Enable: ✓
Backup Count: 30
Remote Backup: Configure if desired
```

## High Availability (Optional)

For HA setup with two OPNsense instances:

**System > High Availability > Settings**

```
Synchronize: ✓
Sync Interface: MANAGEMENT
Remote IP: <secondary-opnsense-ip>
```

## Performance Tuning

### 1. Hardware Offloading

**Interfaces > Settings**

Enable:
- ✓ Hardware checksum offload
- ✓ Hardware TCP segmentation offload
- ✓ Hardware large receive offload

### 2. Firewall Optimization

**Firewall > Settings > Advanced**

```
Firewall Optimization: conservative
Firewall Maximum States: 100000
Firewall Maximum Tables: 5000
```

### 3. System Tuning

**System > Settings > Tunables**

Add:
```
net.inet.ip.intr_queue_maxlen = 2048
kern.ipc.maxsockbuf = 16777216
net.inet.tcp.sendbuf_max = 16777216
net.inet.tcp.recvbuf_max = 16777216
```

## Troubleshooting

### Can't Access Web UI

```bash
# Check VM is running
VBoxManage list runningvms

# Check interface configuration
# From OPNsense console: Select option 2

# Verify host can reach management network
ping 172.25.40.1
```

### Network Not Working

```bash
# Check VirtualBox networks
VBoxManage list hostonlyifs

# Verify DHCP is running
# OPNsense console: Services > DHCPv4

# Check firewall rules
# Web UI: Firewall > Rules
# Ensure pass rules exist
```

### IDS/IPS Not Starting

```bash
# Check Suricata logs
# Web UI: Services > Intrusion Detection > Alerts

# Verify rules are downloaded
# Download tab should show rulesets

# Restart service
# Services > Intrusion Detection > Administration
# Click "Restart"
```

### VPN Not Connecting

```bash
# Check WireGuard status
# Web UI: VPN > WireGuard > Status

# Verify firewall rule on WAN
# Firewall > Rules > WAN
# UDP port 51820 should be open

# Check logs
# System > Log Files > General
```

## Security Checklist

After initial setup:

- [ ] Change default root password
- [ ] Enable HTTPS for web UI
- [ ] Configure SSL certificate
- [ ] Enable two-factor authentication
- [ ] Review all firewall rules
- [ ] Enable IDS/IPS
- [ ] Configure logging to SIEM
- [ ] Set up automated backups
- [ ] Test VPN connectivity
- [ ] Verify network segmentation
- [ ] Document all changes

## Integration with Other Services

### Connect Docker Containers

For Docker containers to use OPNsense as gateway:

```bash
# On Docker host
sudo ip route add 172.25.10.0/24 via 172.25.40.1
sudo ip route add 172.25.20.0/24 via 172.25.40.1
sudo ip route add 172.25.30.0/24 via 172.25.40.1
```

### Add Firewall Rules for Services

Add specific rules for each service in [architecture-networks.tf](architecture-networks.tf).

## Next Steps

1. Deploy services to appropriate networks
2. Configure service-specific firewall rules
3. Set up monitoring dashboards
4. Test security controls
5. Implement backup procedures

## References

- [OPNsense Documentation](https://docs.opnsense.org/)
- [VirtualBox Networking](https://www.virtualbox.org/manual/ch06.html)
- [Suricata IDS](https://suricata.readthedocs.io/)
- [WireGuard VPN](https://www.wireguard.com/)

## Support

For issues specific to this Terraform deployment:
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Review Terraform state: `terraform show`
- Check logs: `terraform output opnsense_info`

---

**Created for CyberLab Project** - Defense-in-Depth Architecture Implementation
