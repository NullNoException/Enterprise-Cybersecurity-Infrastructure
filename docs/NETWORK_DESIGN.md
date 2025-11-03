# Network Design & Topology

## Overview

This document provides detailed network design, IP addressing, traffic flow, and firewall rules for the CyberLab infrastructure.

## Network Segments

### Complete Network Topology

```
┌───────────────────────────────────────────────────────────────────────┐
│                         INTERNET / REMOTE USERS                        │
└─────────────────────────────────┬─────────────────────────────────────┘
                                  │
                    ┌─────────────┴──────────────┐
                    │   VPN Gateway Layer        │
                    ├────────────────────────────┤
                    │ WireGuard    : 51820/udp   │
                    │ OpenVPN      : 1194/udp    │
                    │ Network      : 172.20.0.0  │
                    └─────────────┬──────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │         EXTERNAL NETWORK (172.20.0.0/24)          │
        │                                                    │
        │  • WireGuard VPN        : 172.20.0.20            │
        │  • OpenVPN Server       : 172.20.0.21            │
        │  • OPNsense External IF : 172.20.0.10            │
        └─────────────────────────┬─────────────────────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │    OPNsense NGFW           │
                    │    (Multi-Interface)       │
                    │                            │
                    │  External  : 172.20.0.10   │
                    │  DMZ       : 172.20.10.1   │
                    │  Internal  : 172.20.20.1   │
                    │  Security  : 172.20.30.1   │
                    └─────────────┬──────────────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            │                     │                     │
            │                     │                     │
┌───────────▼──────────┐  ┌───────▼─────────┐  ┌──────▼──────────┐
│   DMZ NETWORK        │  │ INTERNAL NET    │  │ SECURITY NET    │
│   172.20.10.0/24     │  │ 172.20.20.0/24  │  │ 172.20.30.0/24  │
├──────────────────────┤  ├─────────────────┤  ├─────────────────┤
│                      │  │                 │  │                 │
│ Nginx       : .10    │  │ PostgreSQL : .30│  │ Elastic    : .10│
│ T-Pot       : .50    │  │ OpenLDAP   : .40│  │ Kibana     : .11│
│                      │  │ phpLDAP    : .41│  │ Wazuh Mgr  : .20│
│                      │  │ Rocket.Chat: .50│  │ Wazuh UI   : .21│
│                      │  │ MongoDB    : .51│  │ Filebeat   : .22│
│                      │  │ Wazuh Agt  : .60│  │ Logstash   : .30│
│                      │  │ RADIUS     : .70│  │ TheHive    : .40│
│                      │  │                 │  │ Cortex     : .41│
│                      │  │                 │  │ AI Analyze : .50│
│                      │  │                 │  │ Ollama     : .51│
│                      │  │                 │  │ Prometheus : .60│
└──────────────────────┘  └─────────────────┘  └─────────────────┘
                                  │
                          ┌───────▼──────────┐
                          │ MANAGEMENT NET   │
                          │ 172.20.40.0/24   │
                          ├──────────────────┤
                          │                  │
                          │ Prometheus  : .10│
                          │ Grafana     : .11│
                          │ RADIUS      : .20│
                          │ Backup      : .30│
                          │ Node Export : .40│
                          │ cAdvisor    : .41│
                          └──────────────────┘
```

## Detailed IP Addressing

### External Network (172.20.0.0/24)
| IP | Service | Container | Ports | Purpose |
|---|---------|-----------|-------|---------|
| 172.20.0.1 | Gateway | Docker | - | Network gateway |
| 172.20.0.10 | OPNsense External | opnsense | 8443, 8080 | Firewall external interface |
| 172.20.0.20 | WireGuard | wireguard | 51820/udp | Modern VPN |
| 172.20.0.21 | OpenVPN | openvpn | 1194/udp | Legacy VPN |

### DMZ Network (172.20.10.0/24)
| IP | Service | Container | Ports | Purpose |
|---|---------|-----------|-------|---------|
| 172.20.10.1 | OPNsense DMZ | opnsense | - | Firewall DMZ interface |
| 172.20.10.10 | Nginx | nginx | 80, 443 | Reverse proxy & web server |
| 172.20.10.50 | T-Pot | tpot | 64295, 64297 | Honeypot platform |

### Internal Network (172.20.20.0/24)
| IP | Service | Container | Ports | Purpose |
|---|---------|-----------|-------|---------|
| 172.20.20.1 | OPNsense Internal | opnsense | - | Firewall internal interface |
| 172.20.20.10 | Nginx Internal | nginx | - | Backend proxy interface |
| 172.20.20.30 | PostgreSQL | postgresql | 5432 | Database server |
| 172.20.20.40 | OpenLDAP | openldap | 389, 636 | Directory service |
| 172.20.20.41 | phpLDAPadmin | phpldapadmin | 443 | LDAP web interface |
| 172.20.20.50 | Rocket.Chat | rocketchat | 3000 | Communication platform |
| 172.20.20.51 | MongoDB | mongodb | 27017 | Rocket.Chat database |
| 172.20.20.60 | Wazuh Agent IF | wazuh | 1514, 1515 | SIEM agent interface |
| 172.20.20.70 | FreeRADIUS | freeradius | 1812, 1813 | AAA server |

### Security Network (172.20.30.0/24)
| IP | Service | Container | Ports | Purpose |
|---|---------|-----------|-------|---------|
| 172.20.30.1 | OPNsense Security | opnsense | - | Firewall security interface |
| 172.20.30.10 | Elasticsearch | elasticsearch | 9200 | Log storage & search |
| 172.20.30.11 | Kibana | kibana | 5601 | Log visualization |
| 172.20.30.20 | Wazuh Manager | wazuh | 55000, 514 | SIEM manager |
| 172.20.30.21 | Wazuh Dashboard | wazuh-dashboard | 5601 | SIEM UI |
| 172.20.30.22 | Filebeat | filebeat | - | Log shipper |
| 172.20.30.30 | Logstash | logstash | 5000, 5044, 9600 | Log processor |
| 172.20.30.40 | TheHive | thehive | 9000 | Incident response |
| 172.20.30.41 | Cortex | cortex | 9001 | Analysis engine |
| 172.20.30.50 | AI Analyzer | ai-analyzer | - | ML log analysis |
| 172.20.30.51 | Ollama | ollama | 11434 | LLM inference |
| 172.20.30.60 | Prometheus | prometheus | 9090 | Metrics collection |

### Management Network (172.20.40.0/24)
| IP | Service | Container | Ports | Purpose |
|---|---------|-----------|-------|---------|
| 172.20.40.1 | Gateway | Docker | - | Network gateway |
| 172.20.40.10 | Prometheus | prometheus | 9090 | Metrics storage |
| 172.20.40.11 | Grafana | grafana | 3000 | Monitoring dashboard |
| 172.20.40.20 | FreeRADIUS | freeradius | 1812, 1813 | Network AAA |
| 172.20.40.30 | Backup | backup | - | Backup service |
| 172.20.40.40 | Node Exporter | node-exporter | 9100 | System metrics |
| 172.20.40.41 | cAdvisor | cadvisor | 8080 | Container metrics |

## Traffic Flow Patterns

### 1. User Web Access Flow

```
Remote User
    ↓
VPN (WireGuard/OpenVPN) [172.20.0.20/21]
    ↓ Authenticated & Encrypted
OPNsense Firewall [172.20.0.10]
    ↓ Firewall Rules Applied
    ↓ Traffic Mirrored → Suricata IDS
DMZ Network [172.20.10.0/24]
    ↓
Nginx Reverse Proxy [172.20.10.10]
    ↓ TLS Termination
    ├─→ /grafana → Grafana [172.20.40.11]
    ├─→ /kibana → Kibana [172.20.30.11]
    ├─→ /wazuh → Wazuh Dashboard [172.20.30.21]
    ├─→ /thehive → TheHive [172.20.30.40]
    └─→ /chat → Rocket.Chat [172.20.20.50]
    ↓
Logging → Filebeat → Logstash → Elasticsearch
```

### 2. Authentication Flow

```
User Credentials
    ↓
Service (any)
    ↓
LDAP Query [172.20.20.40]
    ↓
OpenLDAP Directory
    ├─→ User Found → Grant Access
    └─→ Not Found → Deny Access
    ↓
RADIUS Accounting [172.20.40.20]
    ↓
Wazuh SIEM [172.20.30.20]
    ↓
Log Event → Elasticsearch
```

### 3. Log Collection Flow

```
All Containers
    ↓ Docker Logs
Filebeat [172.20.30.22]
    ↓ Parsed & Tagged
Logstash [172.20.30.30]
    ↓ Enriched (GeoIP, Patterns)
Elasticsearch [172.20.30.10]
    ↓
    ├─→ Kibana [172.20.30.11] (Visualization)
    ├─→ Wazuh [172.20.30.20] (Correlation)
    └─→ AI Analyzer [172.20.30.50] (ML Analysis)
         ↓
    High Severity?
         ├─→ Yes → TheHive Case [172.20.30.40]
         └─→ No → Index only
```

### 4. IDS Alert Flow

```
Network Traffic
    ↓ Port Mirroring
Suricata IDS [Host Network]
    ↓ Alert Generated
eve.json (Suricata log)
    ↓
Logstash [172.20.30.30]
    ↓ Parse & Enrich
Elasticsearch [172.20.30.10]
    ↓
    ├─→ Wazuh (Correlation)
    └─→ AI Analyzer
         ↓
    Critical Alert?
         ├─→ Yes → TheHive + Webhook
         └─→ No → Dashboard only
```

### 5. Backup Flow

```
Scheduled (Daily 2 AM)
    ↓
Backup Service [172.20.40.30]
    ↓
Collect Data:
    ├─→ Elasticsearch data [172.20.30.10]
    ├─→ PostgreSQL dump [172.20.20.30]
    ├─→ LDAP data [172.20.20.40]
    ├─→ Wazuh configs [172.20.30.20]
    └─→ All configs [/configs]
    ↓
Restic (Incremental)
    ↓
Backup Repository [/backup-repo volume]
    ↓
Retention: 30 days
```

## Firewall Rules (OPNsense)

### Interface Definitions
- **WAN**: External Network (172.20.0.0/24)
- **DMZ**: DMZ Network (172.20.10.0/24)
- **LAN**: Internal Network (172.20.20.0/24)
- **SEC**: Security Network (172.20.30.0/24)
- **MGT**: Management Network (172.20.40.0/24)

### Default Policies
```
WAN → DMZ:   DENY (except VPN → Nginx)
WAN → LAN:   DENY
WAN → SEC:   DENY
WAN → MGT:   DENY

DMZ → LAN:   ALLOW (HTTP/HTTPS to backends)
DMZ → SEC:   ALLOW (Logs only)
DMZ → MGT:   DENY
DMZ → WAN:   DENY

LAN → SEC:   ALLOW (Logs)
LAN → MGT:   ALLOW (Metrics)
LAN → DMZ:   DENY
LAN → WAN:   DENY

SEC → LAN:   DENY (Read-only logs)
SEC → MGT:   ALLOW (Alerts)
SEC → DMZ:   DENY
SEC → WAN:   DENY

MGT → SEC:   ALLOW (Query logs)
MGT → LAN:   ALLOW (LDAP queries)
MGT → DMZ:   DENY
MGT → WAN:   DENY
```

### Specific Allow Rules

#### WAN → DMZ
```
Rule 1: VPN → Nginx
  Source: 172.20.0.20/32, 172.20.0.21/32
  Destination: 172.20.10.10
  Ports: 80, 443
  Protocol: TCP
  Action: ALLOW
```

#### DMZ → LAN
```
Rule 2: Nginx → PostgreSQL
  Source: 172.20.10.10
  Destination: 172.20.20.30
  Ports: 5432
  Protocol: TCP
  Action: ALLOW

Rule 3: Nginx → LDAP
  Source: 172.20.10.10
  Destination: 172.20.20.40
  Ports: 389, 636
  Protocol: TCP
  Action: ALLOW

Rule 4: Nginx → Rocket.Chat
  Source: 172.20.10.10
  Destination: 172.20.20.50
  Ports: 3000
  Protocol: TCP
  Action: ALLOW
```

#### ANY → SEC (Logging)
```
Rule 5: All → Logstash
  Source: ANY
  Destination: 172.20.30.30
  Ports: 514, 5000, 5044
  Protocol: TCP/UDP
  Action: ALLOW

Rule 6: All → Elasticsearch (Logs)
  Source: 172.20.10.0/24, 172.20.20.0/24
  Destination: 172.20.30.10
  Ports: 9200
  Protocol: TCP
  Action: ALLOW
```

#### LAN → MGT (Metrics)
```
Rule 7: Services → Prometheus
  Source: 172.20.20.0/24
  Destination: 172.20.40.10
  Ports: 9090
  Protocol: TCP
  Action: ALLOW
```

## Port Mapping (Host → Container)

### Exposed Ports on Host

| Host Port | Container | Service | Purpose |
|-----------|-----------|---------|---------|
| 80 | nginx:80 | HTTP | Web (redirects to HTTPS) |
| 443 | nginx:443 | HTTPS | Secure web access |
| 3000 | grafana:3000 | Grafana | Monitoring dashboard |
| 3100 | rocketchat:3000 | Rocket.Chat | Team communication |
| 5601 | kibana:5601 | Kibana | Log visualization |
| 5602 | wazuh-dashboard:5601 | Wazuh | SIEM dashboard |
| 6443 | phpldapadmin:443 | LDAP Admin | LDAP management |
| 8080 | opnsense:80 | Firewall HTTP | Firewall redirect |
| 8081 | cadvisor:8080 | cAdvisor | Container metrics |
| 8443 | opnsense:443 | Firewall HTTPS | Firewall management |
| 9000 | thehive:9000 | TheHive | Incident response |
| 9001 | cortex:9001 | Cortex | Analysis engine |
| 9090 | prometheus:9090 | Prometheus | Metrics backend |
| 9100 | node-exporter:9100 | Node Exporter | System metrics |
| 9200 | elasticsearch:9200 | Elasticsearch | Search API |
| 11434 | ollama:11434 | Ollama | LLM API |
| 51820 | wireguard:51820/udp | WireGuard | VPN |
| 1194 | openvpn:1194/udp | OpenVPN | VPN |
| 1812 | freeradius:1812/udp | RADIUS | Authentication |
| 1813 | freeradius:1813/udp | RADIUS | Accounting |

## Network Security Controls

### 1. Network Segmentation
- **5 isolated networks** prevent lateral movement
- **Firewall between all segments** enforces policies
- **DMZ isolation** protects internal services

### 2. Traffic Inspection
- **All traffic through firewall** (no bypass)
- **Suricata IDS** monitors all network activity
- **Port mirroring** to security network

### 3. Access Control
- **VPN required** for external access
- **LDAP authentication** for all services
- **RADIUS accounting** for network access
- **Network-level ACLs** on firewall

### 4. Monitoring
- **Full packet capture** (optional via Suricata)
- **Flow logs** to Elasticsearch
- **Real-time alerting** via Wazuh
- **Network metrics** via Prometheus

## DNS & Service Discovery

### Internal DNS
Services discover each other using Docker's embedded DNS:

```
# Within same network
postgresql → 172.20.20.30 (automatic)

# Across networks
nginx → postgres:5432 (Docker DNS resolves)
```

### External DNS
For production, configure:
- **Internal domain**: cyberlab.local
- **External domain**: your.domain.com
- **Split DNS**: Internal services on .local

## Network Performance

### Bandwidth Allocation
- **Management Traffic**: High priority
- **Security Logs**: High priority
- **User Traffic**: Medium priority
- **Backup Traffic**: Low priority (QoS)

### Latency Targets
- **Inter-container**: < 1ms
- **Service response**: < 100ms
- **Log ingestion**: < 1s
- **Alert generation**: < 5s

## Troubleshooting

### Check Network Connectivity

```bash
# List all networks
docker network ls

# Inspect network details
docker network inspect cyberlab_dmz_net

# Test connectivity
docker exec nginx ping -c 3 elasticsearch

# Check DNS resolution
docker exec nginx nslookup elasticsearch

# View routing
docker exec nginx ip route
```

### Common Network Issues

**Issue**: Container can't reach another container
```bash
# Solution: Check if containers are on same network
docker inspect <container1> | grep Networks
docker inspect <container2> | grep Networks
```

**Issue**: Service not accessible from host
```bash
# Solution: Check port mapping
docker port <container-name>
netstat -an | grep <port>
```

**Issue**: Firewall blocking traffic
```bash
# Solution: Check OPNsense logs
docker logs opnsense | grep BLOCK
```

## Network Diagrams

### Simplified Traffic Flow

```
┌──────┐
│ User │
└──┬───┘
   │ 1. VPN Connect
   ▼
┌──────────┐
│   VPN    │
└──┬───────┘
   │ 2. Authenticate (RADIUS+LDAP)
   ▼
┌──────────┐
│ Firewall │────┐ 3. Mirror
└──┬───────┘    │
   │ 4. Route   ▼
   │         ┌─────┐
   │         │ IDS │
   ▼         └─────┘
┌──────────┐
│   DMZ    │
└──┬───────┘
   │ 5. Reverse Proxy
   ▼
┌──────────┐
│ Internal │
└──┬───────┘
   │ 6. Log Everything
   ▼
┌──────────┐
│ Security │
└──┬───────┘
   │ 7. Monitor & Alert
   ▼
┌──────────┐
│Mgmt (UI) │
└──────────┘
```

## Security Zones Summary

| Zone | Trust Level | Internet Access | Monitored | Logged |
|------|-------------|----------------|-----------|--------|
| External | Untrusted | Yes | Yes | Yes |
| DMZ | Low | No | Yes | Yes |
| Internal | Medium | No | Yes | Yes |
| Security | High | No | Yes | Yes |
| Management | High | No | Yes | Yes |

---

This network design provides **defense-in-depth** through segmentation, **comprehensive monitoring** through logging, and **centralized control** through the firewall, while maintaining **performance** and **scalability**.
