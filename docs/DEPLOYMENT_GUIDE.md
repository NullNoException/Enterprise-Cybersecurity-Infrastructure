# Deployment Guide - CyberLab Security Infrastructure

## Prerequisites

### System Requirements
- **Operating System**: Windows 10/11 with WSL2 enabled
- **RAM**: 32GB minimum (24GB will be allocated to containers)
- **CPU**: 4 cores minimum (8 recommended)
- **Storage**: 200GB SSD free space
- **Network**: Stable internet connection for initial image downloads

### Required Software

#### 1. Install WSL2
```powershell
# Run in PowerShell as Administrator
wsl --install
wsl --set-default-version 2

# Install Ubuntu
wsl --install -d Ubuntu-22.04
```

#### 2. Install Docker Desktop
1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop
2. Install with WSL2 backend enabled
3. Configure resources in Docker Desktop:
   - CPUs: 4
   - Memory: 24GB
   - Swap: 4GB
   - Disk image size: 150GB

#### 3. Verify Installation
```bash
# In WSL terminal
docker --version
docker-compose --version

# Should output:
# Docker version 24.0+
# Docker Compose version 2.20+
```

## Step-by-Step Deployment

### Step 1: Prepare Project Directory

```bash
# Clone or navigate to project directory
cd /mnt/c/Users/YourUsername/Documents
git clone <repository-url> cyberlab
cd cyberlab

# Or if files are already present:
cd /path/to/Project
```

### Step 2: Initialize Directory Structure

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Initialize directories
./scripts/init-directories.sh
```

Expected output:
```
==================================================
Initializing Cybersecurity Infrastructure
==================================================
[*] Creating configuration directories...
[*] Creating web content...
[*] Setting permissions...

==================================================
✅ Directory structure initialized successfully!
==================================================
```

### Step 3: Generate Secrets and Certificates

```bash
./scripts/generate-secrets.sh
```

This will:
- Create `.env` file with random secure passwords
- Generate SSL certificates for Nginx
- Generate LDAP certificates
- Create initial configurations for all services

**IMPORTANT**: Save the generated passwords from `.env` file securely!

### Step 4: Review Configuration

```bash
# View generated passwords (keep these secure!)
cat .env

# Optional: Customize configurations
nano configs/nginx/nginx.conf
nano configs/suricata/suricata.yaml
```

### Step 5: Configure Docker Resources

Ensure Docker Desktop has sufficient resources:

1. Open Docker Desktop
2. Go to Settings → Resources
3. Set:
   - CPUs: 4
   - Memory: 24 GB
   - Swap: 4 GB

### Step 6: Deploy Infrastructure

```bash
# Deploy all services
docker-compose up -d

# This will:
# - Pull all required Docker images (~15-20GB)
# - Create 5 isolated networks
# - Deploy 30+ containers
# - Configure inter-service communication

# Expected time: 15-30 minutes depending on internet speed
```

### Step 7: Monitor Deployment

```bash
# Watch deployment progress
docker-compose logs -f

# Check container status
docker-compose ps

# All containers should show "Up" status
```

### Step 8: Initialize Services

```bash
# Wait for Elasticsearch to be ready (2-3 minutes)
until curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"'; do
    echo "Waiting for Elasticsearch..."
    sleep 10
done

# Initialize MongoDB replica set for Rocket.Chat
docker exec mongodb mongosh --eval "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongodb:27017'}]})"

# Pull Llama3 model for AI analyzer
docker exec ollama ollama pull llama3
```

### Step 9: Verify Deployment

Access the services to verify they're running:

```bash
# Check all services are responding
curl http://localhost:3000  # Grafana
curl http://localhost:5601  # Kibana
curl http://localhost:9000  # TheHive
curl http://localhost:80    # Nginx

# View infrastructure status
docker-compose ps
```

Expected output: All services showing "Up" and "healthy"

## Post-Deployment Configuration

### 1. Access Web Interface

Open browser and navigate to:
- **Main Portal**: http://localhost (redirects to HTTPS)
- **Grafana**: http://localhost:3000
- **Kibana/ELK**: http://localhost:5601
- **Wazuh Dashboard**: http://localhost:5602
- **TheHive**: http://localhost:9000
- **Rocket.Chat**: http://localhost:3100

### 2. Initial Login Credentials

Retrieve passwords from `.env` file:

```bash
# Display all passwords
grep PASSWORD .env

# Or view specific service password
grep GRAFANA_PASSWORD .env
```

**Default Credentials** (if using template):
- **Grafana**: admin / (see GRAFANA_PASSWORD in .env)
- **Kibana**: elastic / (see ELASTIC_PASSWORD in .env)
- **Wazuh**: admin / (see WAZUH_API_PASSWORD in .env)
- **TheHive**: admin@thehive.local / secret
- **Rocket.Chat**: admin / (see ROCKETCHAT_PASSWORD in .env)

### 3. Configure LDAP Users

```bash
# Access OpenLDAP container
docker exec -it openldap bash

# Add users using ldapadd
ldapadd -x -D "cn=admin,dc=cyberlab,dc=local" -W -f /container/service/slapd/assets/config/bootstrap/init.ldif
```

Or use phpLDAPadmin:
- URL: http://localhost:6443
- Login DN: cn=admin,dc=cyberlab,dc=local
- Password: (see LDAP_ADMIN_PASSWORD in .env)

### 4. Configure Grafana Dashboards

1. Login to Grafana (http://localhost:3000)
2. Navigate to Configuration → Data Sources
3. Add Prometheus:
   - URL: http://prometheus:9090
   - Click "Save & Test"
4. Import security dashboard:
   - Navigate to Dashboards → Import
   - Upload `/dashboards/security-overview.json`

### 5. Configure Wazuh Agents

To monitor external systems, install Wazuh agents:

```bash
# Get Wazuh manager IP
docker inspect wazuh | grep IPAddress

# On target system (Linux):
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
apt-get update
apt-get install wazuh-agent

# Configure agent
echo "WAZUH_MANAGER='<wazuh-manager-ip>'" > /var/ossec/etc/ossec.conf
systemctl restart wazuh-agent
```

### 6. Configure VPN Access

#### WireGuard Setup:

```bash
# Generate client configuration
docker exec wireguard /app/show-peer <peer-name>

# Download configuration
docker cp wireguard:/config/peer_<peer-name>/peer_<peer-name>.conf ./wireguard-client.conf

# Use with WireGuard client
```

### 7. Set Up Backup Schedule

The backup service runs automatically, but you can trigger manual backups:

```bash
# Run manual backup
docker exec backup /usr/local/bin/backup.sh

# List snapshots
docker exec backup restic -r /backup-repo snapshots

# Restore from backup
docker exec backup restic -r /backup-repo restore latest --target /restore
```

## Network Topology Verification

```bash
# Verify all networks are created
docker network ls | grep cyberlab

# Should show:
# - cyberlab_external_net
# - cyberlab_dmz_net
# - cyberlab_internal_net
# - cyberlab_security_net
# - cyberlab_management_net

# Inspect network
docker network inspect cyberlab_dmz_net
```

## Security Hardening Checklist

- [ ] Change all default passwords in `.env`
- [ ] Review firewall rules in OPNsense
- [ ] Configure VPN certificates
- [ ] Set up LDAP user accounts
- [ ] Enable 2FA on critical services
- [ ] Configure email notifications
- [ ] Review Suricata IDS rules
- [ ] Test backup and restore procedures
- [ ] Configure log retention policies
- [ ] Set up Rocket.Chat webhooks for alerts

## Troubleshooting

### Services Not Starting

```bash
# Check logs for specific service
docker-compose logs <service-name>

# Common issues:
# 1. Insufficient memory - increase Docker memory allocation
# 2. Port conflicts - check if ports are already in use
# 3. Permission issues - ensure directories have correct permissions
```

### Elasticsearch Not Healthy

```bash
# Check cluster health
curl -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health?pretty

# Increase memory if needed (edit docker-compose.yml)
# ES_JAVA_OPTS: "-Xms4g -Xmx4g"
```

### Container Crashes or Restarts

```bash
# View container logs
docker logs <container-name>

# Check resource usage
docker stats

# Restart specific service
docker-compose restart <service-name>
```

### Network Connectivity Issues

```bash
# Test connectivity between containers
docker exec nginx ping -c 3 elasticsearch
docker exec wazuh ping -c 3 elasticsearch

# Check DNS resolution
docker exec nginx nslookup elasticsearch
```

### Ollama Model Not Loading

```bash
# Manually pull model
docker exec ollama ollama pull llama3

# Check available models
docker exec ollama ollama list

# View AI analyzer logs
docker logs ai-analyzer -f
```

## Maintenance

### Regular Updates

```bash
# Update all containers (run weekly)
./scripts/update-all.sh
```

### Log Management

```bash
# View log sizes
docker exec elasticsearch curl -s localhost:9200/_cat/indices?v

# Manually delete old indices
docker exec elasticsearch curl -X DELETE localhost:9200/logstash-2024.01.01
```

### Health Checks

```bash
# Check all services
docker-compose ps

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# View Grafana dashboards for system health
```

## Scaling Considerations

For production with more resources:

1. **Increase Elasticsearch cluster**:
   - Add more Elasticsearch nodes in docker-compose.yml
   - Increase heap size

2. **Separate containers across hosts**:
   - Use Docker Swarm or Kubernetes
   - Deploy each network layer on separate hosts

3. **Add load balancers**:
   - HAProxy or Traefik for service distribution

4. **External storage**:
   - NFS or cloud storage for data volumes

## Backup and Disaster Recovery

### Backup All Configurations

```bash
# Manual backup
tar -czf cyberlab-backup-$(date +%Y%m%d).tar.gz \
    configs/ \
    .env \
    docker-compose.yml \
    scripts/

# Store offsite
```

### Full Disaster Recovery

```bash
# 1. Restore project files
tar -xzf cyberlab-backup-YYYYMMDD.tar.gz

# 2. Restore data volumes
docker exec backup restic -r /backup-repo restore latest --target /restore

# 3. Redeploy
docker-compose down -v
docker-compose up -d
```

## Support and Resources

- **Logs**: `docker-compose logs -f`
- **Documentation**: `/docs` directory
- **Dashboard**: http://localhost:3000 (Grafana)
- **SIEM**: http://localhost:5602 (Wazuh)

For issues, check service-specific logs and documentation in the `/docs` directory.
