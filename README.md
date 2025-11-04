# Enterprise Cybersecurity Infrastructure - Docker Deployment

## Overview
This project provides a complete on-premises cybersecurity infrastructure deployed using Docker Desktop + WSL2. It implements defense-in-depth with layered network topology, comprehensive security monitoring, and enterprise-grade access controls.

## System Requirements
- **OS**: Windows 10/11 with WSL2
- **RAM**: 32GB (minimum)
- **CPU**: 4 cores (minimum)
- **Storage**: 200GB SSD
- **Software**: Docker Desktop with WSL2 integration

## Architecture Overview

### Network Layers
1. **External Network** (172.25.0.0/24) - VPN entry point
2. **DMZ Network** (172.25.10.0/24) - Public-facing services
3. **Internal Network** (172.25.20.0/24) - Protected internal services
4. **Security Network** (172.25.30.0/24) - Security tools and monitoring
5. **Management Network** (172.25.40.0/24) - Administration and monitoring

### Component Matrix

| Component | Technology | Network | Purpose |
|-----------|-----------|---------|---------|
| NGFW | OPNsense | External/DMZ/Internal | Traffic filtering and routing |
| VPN Gateway | WireGuard + OpenVPN | External | Secure remote access |
| SIEM | Wazuh + ELK Stack | Security | Security information and event management |
| IPS/IDS | Suricata | Security | Intrusion detection and prevention |
| Honeypot | T-Pot | DMZ | Threat intelligence collection |
| LDAP/AD | OpenLDAP + Samba | Internal | Directory services |
| RADIUS | FreeRADIUS | Management | Network access authentication |
| Web Server | Nginx | DMZ | Reverse proxy and web hosting |
| Database | PostgreSQL | Internal | Data persistence |
| Backup | Restic | Management | Configuration and data backup |
| Communication | Rocket.Chat | Internal | Team collaboration |
| AI Analyzer | Ollama (Llama3) | Security | Log analysis and anomaly detection |
| Dashboard | Grafana + Prometheus | Management | Monitoring and visualization |
| Forensics | TheHive + Cortex | Security | Incident response |

## Traffic Flow
1. All external traffic enters via VPN Gateway
2. VPN forwards to OPNsense NGFW
3. NGFW applies rules and routes to DMZ or Internal networks
4. All traffic is mirrored to Suricata IDS
5. Logs are collected by Filebeat/Logstash
6. Logs analyzed by AI service and stored in Elasticsearch
7. Wazuh SIEM correlates events and generates alerts
8. Grafana provides real-time visualization

## Quick Start

### 1. Prerequisites
```bash
# Ensure WSL2 is installed
wsl --install

# Install Docker Desktop with WSL2 backend
# Download from https://www.docker.com/products/docker-desktop

# Verify installation
docker --version
docker-compose --version
```

### 2. Deploy Infrastructure
```bash
# Clone or navigate to project directory
cd /path/to/project

# Create required directories
./scripts/init-directories.sh

# Generate certificates and secrets
./scripts/generate-secrets.sh

# Deploy full stack
docker-compose up -d

# Monitor deployment
docker-compose logs -f
```

### 3. Access Services

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Grafana Dashboard | http://localhost:3000 | admin/admin |
| Kibana (SIEM) | http://localhost:5601 | elastic/changeme |
| Wazuh UI | http://localhost:5602 | admin/SecretPassword |
| OPNsense NGFW | https://localhost:8443 | root/opnsense |
| TheHive | http://localhost:9000 | admin@thehive.local/secret |
| Rocket.Chat | http://localhost:3100 | Setup on first access |

## Security Hardening
- All passwords in `.env` file (excluded from git)
- TLS encryption for all services
- Network segmentation enforced by firewall rules
- Least privilege access via LDAP groups
- Regular automated backups
- Audit logging enabled on all services

## Resource Allocation

| Service | CPU | RAM | Notes |
|---------|-----|-----|-------|
| Elasticsearch | 1.0 | 4GB | SIEM backend |
| Wazuh Manager | 0.5 | 2GB | SIEM manager |
| Suricata | 1.0 | 2GB | IDS/IPS |
| OPNsense | 1.0 | 2GB | Firewall |
| PostgreSQL | 0.5 | 1GB | Database |
| Grafana | 0.3 | 512MB | Monitoring |
| Ollama | 1.0 | 4GB | AI analysis |
| Others | 1.7 | 8GB | Remaining services |
| **Total** | ~4.0 | ~24GB | Fits in 32GB system |

## Monitoring and Alerts

### Real-Time Dashboards
1. **Security Overview** - Grafana dashboard showing:
   - Active threats and IDS alerts
   - Authentication failures
   - Network traffic patterns
   - Service health status

2. **Network Topology** - Live network visualization
3. **Log Analysis** - AI-powered anomaly detection

### Alert Channels
- Email notifications
- Webhook to Rocket.Chat
- SIEM console alerts

## Backup Strategy
- **Automated**: Daily incremental backups at 2 AM
- **Retention**: 30 days
- **Scope**:
  - All configuration files
  - Database dumps
  - Security logs
  - SIEM indices (last 7 days)

## Maintenance

### Log Rotation
- Elasticsearch: 30-day retention
- Application logs: 14-day retention
- IDS logs: 60-day retention

### Updates
```bash
# Update all containers
./scripts/update-all.sh

# Update specific service
docker-compose pull <service_name>
docker-compose up -d <service_name>
```

## Troubleshooting

### Check Service Health
```bash
docker-compose ps
docker-compose logs <service_name>
```

### Network Connectivity
```bash
# List all networks
docker network ls

# Inspect network
docker network inspect cyberlab_dmz
```

### Reset Environment
```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Rebuild and restart
docker-compose up -d --build
```

## Project Structure
```
.
├── docker-compose.yml              # Main orchestration file
├── .env                           # Environment variables (gitignored)
├── configs/                       # Service configurations
│   ├── opnsense/
│   ├── suricata/
│   ├── wazuh/
│   ├── nginx/
│   ├── ldap/
│   └── radius/
├── scripts/                       # Automation scripts
│   ├── init-directories.sh
│   ├── generate-secrets.sh
│   ├── update-all.sh
│   └── backup.sh
├── ai-analyzer/                   # AI log analysis service
│   ├── Dockerfile
│   ├── analyzer.py
│   └── requirements.txt
├── dashboards/                    # Grafana dashboards
│   └── security-overview.json
└── docs/                         # Additional documentation
    ├── ARCHITECTURE.md
    ├── NETWORK_DESIGN.md
    └── SECURITY_POLICIES.md
```

## License
Educational/Research Use Only

## Support
For issues and questions, refer to individual component documentation in `/docs` directory.
