# Architecture Documentation

## Overview

This document describes the architecture of the CyberLab cybersecurity infrastructure, including network topology, component interactions, and security design principles.

## Design Principles

### 1. Defense in Depth
Multiple layers of security controls to protect against various attack vectors:
- **Perimeter Security**: VPN, Firewall
- **Network Segmentation**: DMZ, Internal, Security zones
- **Access Control**: AAA (Authentication, Authorization, Accounting)
- **Monitoring**: IDS/IPS, SIEM, Log Analysis
- **Data Protection**: Encryption, Backups

### 2. Zero Trust Architecture
- All network traffic passes through the firewall
- Authentication required for all services
- Least privilege access model
- Continuous monitoring and verification

### 3. Layered Network Topology
Five distinct network segments with controlled traffic flow:
```
External → DMZ → Internal
            ↓      ↓
        Security ← Management
```

## Network Architecture

### Network Segments

#### 1. External Network (172.20.0.0/24)
**Purpose**: Entry point for external access

**Components**:
- VPN Gateway (WireGuard + OpenVPN)
- External interface of OPNsense firewall

**Traffic Flow**:
- Inbound: VPN connections from remote users
- Outbound: To DMZ and Internal networks (filtered)

**Security Controls**:
- VPN authentication required
- All traffic inspected by firewall
- Rate limiting on VPN endpoints

#### 2. DMZ Network (172.20.10.0/24)
**Purpose**: Host public-facing services

**Components**:
- Nginx Reverse Proxy (172.20.10.10)
- T-Pot Honeypot (172.20.10.50)
- OPNsense DMZ interface (172.20.10.1)

**Traffic Flow**:
- Inbound: From External network (restricted)
- Outbound: To Internal network for backend services
- Monitored: All traffic logged and analyzed

**Security Controls**:
- No direct internet access
- Strict firewall rules
- All services behind reverse proxy
- Honeypot for threat intelligence

#### 3. Internal Network (172.20.20.0/24)
**Purpose**: Protected internal services and data

**Components**:
- PostgreSQL Database (172.20.20.30)
- OpenLDAP Directory (172.20.20.40)
- Rocket.Chat (172.20.20.50)
- MongoDB (172.20.20.51)
- Wazuh Manager (172.20.20.60)
- FreeRADIUS (172.20.20.70)

**Traffic Flow**:
- Inbound: From DMZ (application traffic only)
- Outbound: To Security network (logs)
- Isolated: No direct external access

**Security Controls**:
- LDAP authentication for all services
- Database encryption at rest
- Network isolation from DMZ
- All access logged

#### 4. Security Network (172.20.30.0/24)
**Purpose**: Security monitoring and analysis

**Components**:
- Elasticsearch (172.20.30.10)
- Kibana (172.20.30.11)
- Wazuh Manager (172.20.30.20)
- Wazuh Dashboard (172.20.30.21)
- Filebeat (172.20.30.22)
- Logstash (172.20.30.30)
- TheHive (172.20.30.40)
- Cortex (172.20.30.41)
- AI Analyzer (172.20.30.50)
- Ollama (172.20.30.51)
- Prometheus (172.20.30.60)

**Traffic Flow**:
- Inbound: Logs from all networks
- Outbound: Alerts to Management network
- Mirror: IDS/IPS traffic mirroring

**Security Controls**:
- Read-only access from other networks
- Encrypted log transmission
- Tamper-evident log storage
- Isolated from production traffic

#### 5. Management Network (172.20.40.0/24)
**Purpose**: Administrative and monitoring interfaces

**Components**:
- Prometheus (172.20.40.10)
- Grafana (172.20.40.11)
- FreeRADIUS (172.20.40.20)
- Backup Service (172.20.40.30)
- Node Exporter (172.20.40.40)
- cAdvisor (172.20.40.41)

**Traffic Flow**:
- Inbound: Metrics from all networks
- Outbound: Management commands (authenticated)
- Isolated: Separate from production traffic

**Security Controls**:
- MFA required for admin access
- LDAP authentication
- Audit logging
- IP allowlisting for admin access

## Component Architecture

### 1. Security Monitoring Stack

```
┌─────────────────────────────────────────────┐
│           Data Collection Layer             │
├─────────────────────────────────────────────┤
│ Filebeat │ Logstash │ Suricata │ Wazuh Agents│
└──────┬───────┬──────────┬──────────┬─────────┘
       │       │          │          │
       └───────┴──────────┴──────────┘
                     │
       ┌─────────────▼─────────────┐
       │   Elasticsearch Cluster   │
       │   (Indexed Log Storage)   │
       └─────────────┬─────────────┘
                     │
       ┌─────────────┼─────────────┐
       │             │             │
   ┌───▼───┐   ┌────▼────┐   ┌───▼────┐
   │Kibana │   │  Wazuh  │   │   AI   │
   │  UI   │   │Dashboard│   │Analyzer│
   └───────┘   └─────────┘   └────────┘
```

**Data Flow**:
1. All services send logs to Filebeat/Logstash
2. Logs enriched with metadata (GeoIP, threat intel)
3. Indexed in Elasticsearch
4. Analyzed by Wazuh correlation engine
5. AI Analyzer detects anomalies
6. Alerts sent to TheHive for incident response

### 2. Authentication & Authorization Flow

```
┌─────────┐
│  User   │
└────┬────┘
     │ 1. Connect via VPN
     ▼
┌─────────────┐
│ VPN Gateway │
└────┬────────┘
     │ 2. Authenticate
     ▼
┌──────────────┐      ┌──────────┐
│ FreeRADIUS   │◄────►│ OpenLDAP │
└────┬─────────┘      └──────────┘
     │ 3. Authorization check
     ▼
┌──────────────┐
│   Firewall   │
└────┬─────────┘
     │ 4. Apply network policies
     ▼
┌──────────────┐
│   Service    │ (Re-authenticate with LDAP)
└──────────────┘
```

**AAA Components**:
- **Authentication**: LDAP (centralized identity)
- **Authorization**: LDAP groups + RADIUS policies
- **Accounting**: RADIUS logs + Wazuh monitoring

### 3. Intrusion Detection Pipeline

```
Network Traffic
      │
      ▼
┌─────────────┐
│  Suricata   │ (IDS/IPS)
│  Port Mirror│
└────┬────────┘
     │ Alerts + Full Packets
     ▼
┌─────────────┐
│  Logstash   │ (Enrichment)
└────┬────────┘
     │
     ▼
┌─────────────┐
│Elasticsearch│
└────┬────────┘
     │
     ├──► Kibana (Visualization)
     ├──► Wazuh (Correlation)
     └──► AI Analyzer (ML Detection)
              │
              ▼
          ┌────────┐
          │TheHive │ (Case Management)
          └────────┘
```

### 4. AI Log Analysis Architecture

```
┌──────────────────────────────────────┐
│       Elasticsearch                  │
│       (Raw Logs)                     │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│    AI Analyzer Service               │
│  ┌────────────────────────────────┐  │
│  │ 1. Fetch logs (last 5 min)    │  │
│  └─────────────┬──────────────────┘  │
│                ▼                     │
│  ┌────────────────────────────────┐  │
│  │ 2. Simplify & Aggregate        │  │
│  │    - Group by severity         │  │
│  │    - Extract patterns          │  │
│  │    - Identify anomalies        │  │
│  └─────────────┬──────────────────┘  │
│                ▼                     │
│  ┌────────────────────────────────┐  │
│  │ 3. Send to Ollama (Llama3)    │  │
│  │    - Analyze for threats       │  │
│  │    - Generate recommendations  │  │
│  └─────────────┬──────────────────┘  │
│                ▼                     │
│  ┌────────────────────────────────┐  │
│  │ 4. Parse AI Response          │  │
│  │    - Extract severity          │  │
│  │    - Identify threats          │  │
│  └─────────────┬──────────────────┘  │
└────────────────┼────────────────────┘
                 │
                 ├──► Elasticsearch (Alert Index)
                 ├──► Wazuh (High severity)
                 └──► Rocket.Chat (Webhook)
```

**AI Analysis Features**:
- **Anomaly Detection**: Statistical + ML-based
- **Pattern Recognition**: Identifies attack patterns
- **Threat Correlation**: Links related events
- **Automatic Triage**: Prioritizes incidents
- **Natural Language**: Human-readable insights

## Data Flow Diagrams

### 1. Web Traffic Flow

```
Internet
   │
   ▼
VPN Gateway
   │
   ▼
OPNsense Firewall ──┐
   │                │ Mirror traffic
   ▼                ▼
DMZ Network     Suricata IDS
   │
   ▼
Nginx Reverse Proxy
   │
   ├──► /grafana ──► Grafana (Management Net)
   ├──► /kibana ──► Kibana (Security Net)
   ├──► /wazuh ──► Wazuh Dashboard (Security Net)
   ├──► /thehive ──► TheHive (Security Net)
   └──► /chat ──► Rocket.Chat (Internal Net)
```

### 2. Log Collection Flow

```
All Containers
   │
   ├──► Docker Logs ──► Filebeat ──┐
   ├──► Syslog ──────► Logstash ───┤
   └──► App Logs ─────► Direct ────┤
                                    │
                                    ▼
                              Elasticsearch
                                    │
                        ┌───────────┼───────────┐
                        ▼           ▼           ▼
                     Kibana      Wazuh    AI Analyzer
```

### 3. Alert Escalation Flow

```
Event Detected
   │
   ▼
Severity Classification
   │
   ├──► Low ──────► Logged only
   ├──► Medium ───► Dashboard alert
   ├──► High ─────► Email + Dashboard + Webhook
   └──► Critical ─► All above + TheHive case + SMS
```

## Security Controls Matrix

| Layer | Controls | Tools |
|-------|----------|-------|
| **Network** | Segmentation, Firewall, IPS | OPNsense, Suricata |
| **Access** | MFA, SSO, RBAC | LDAP, RADIUS, Grafana Auth |
| **Detection** | IDS, SIEM, Honeypot | Suricata, Wazuh, T-Pot |
| **Analysis** | Log correlation, ML | Wazuh, AI Analyzer |
| **Response** | Case management, Playbooks | TheHive, Cortex |
| **Data** | Encryption, Backup | TLS, Restic |
| **Monitoring** | Metrics, Dashboards | Prometheus, Grafana |

## High Availability Considerations

**Current Setup**: Single-node (suitable for lab/small deployment)

**For Production HA**:
1. **Elasticsearch**: 3-node cluster with master/data separation
2. **Database**: PostgreSQL replication (primary + standby)
3. **LDAP**: Multi-master replication
4. **Firewall**: Active-passive failover
5. **Load Balancing**: HAProxy for service distribution

## Disaster Recovery

**RTO (Recovery Time Objective)**: < 4 hours
**RPO (Recovery Point Objective)**: < 24 hours

**Backup Strategy**:
- Daily incremental backups (2 AM)
- 30-day retention
- Offsite backup storage recommended
- Automated backup verification

**Recovery Procedure**:
1. Restore configurations from backup
2. Redeploy containers
3. Restore data volumes
4. Verify service health
5. Validate network connectivity

## Performance Optimization

### Resource Allocation
- **Elasticsearch**: 4GB RAM (most critical)
- **Ollama**: 4GB RAM (AI model)
- **Wazuh**: 2GB RAM
- **Database**: 1GB RAM
- **Others**: < 1GB each

### Tuning Recommendations
1. **Elasticsearch**:
   - Heap size: 50% of allocated RAM
   - Index refresh interval: 30s
   - Shard count: 1 per index (single node)

2. **Suricata**:
   - Worker threads: Match CPU cores
   - Ring buffer: 2048 packets
   - Rule tuning: Disable unnecessary rules

3. **Docker**:
   - Use overlay2 storage driver
   - Disable unnecessary logging
   - Use resource limits

## Compliance Mapping

| Framework | Implemented Controls |
|-----------|---------------------|
| **NIST CSF** | Identify, Protect, Detect, Respond, Recover |
| **CIS Controls** | Inventory, Access Control, Monitoring, Logging |
| **ISO 27001** | A.12 (Operations), A.13 (Communications) |
| **GDPR** | Data encryption, Access logs, Backup |

## Future Enhancements

1. **SOAR Integration**: Automate incident response
2. **Threat Intelligence Feeds**: Integrate external threat data
3. **Container Scanning**: Vulnerability scanning of images
4. **Service Mesh**: Istio for microservice security
5. **API Gateway**: Centralized API management
6. **WAF**: Web Application Firewall for Nginx

## References

- [Docker Networking](https://docs.docker.com/network/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Elastic Stack](https://www.elastic.co/guide/)
- [Suricata User Guide](https://suricata.readthedocs.io/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
