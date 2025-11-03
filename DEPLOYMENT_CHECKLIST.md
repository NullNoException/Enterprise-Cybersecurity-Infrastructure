# Deployment Checklist

## Pre-Deployment

### System Requirements
- [ ] Windows 10/11 Pro with Hyper-V support
- [ ] WSL2 installed and configured
- [ ] Ubuntu 22.04 installed in WSL2
- [ ] Docker Desktop installed (latest version)
- [ ] 32GB RAM available
- [ ] 4 CPU cores minimum
- [ ] 200GB free disk space (SSD recommended)
- [ ] Stable internet connection

### Docker Configuration
- [ ] Docker Desktop running
- [ ] WSL2 integration enabled in Docker Desktop
- [ ] Resource limits configured:
  - [ ] CPUs: 4
  - [ ] Memory: 24GB
  - [ ] Swap: 4GB
  - [ ] Disk image: 150GB+
- [ ] Docker Compose v2.20+ installed

### File Preparation
- [ ] Project files extracted/cloned to local directory
- [ ] Scripts are executable (`chmod +x scripts/*.sh`)
- [ ] No spaces in file paths
- [ ] OpenSSL installed (for certificate generation)

## Deployment Steps

### Phase 1: Initialization
- [ ] Run `./scripts/init-directories.sh`
- [ ] Verify all directories created
- [ ] Check web/index.html exists
- [ ] Confirm no errors in output

### Phase 2: Secrets Generation
- [ ] Run `./scripts/generate-secrets.sh`
- [ ] Verify `.env` file created
- [ ] Verify SSL certificates generated in `configs/nginx/certs/`
- [ ] Verify LDAP certificates generated in `configs/ldap/certs/`
- [ ] **BACKUP `.env` file to secure location**
- [ ] Record all generated passwords

### Phase 3: Configuration Review
- [ ] Review `.env` file
- [ ] Customize LDAP_ORGANISATION if needed
- [ ] Customize LDAP_DOMAIN if needed
- [ ] Review network IP ranges (if conflicts exist)
- [ ] Check `docker-compose.yml` for any required customizations

### Phase 4: Initial Deployment
- [ ] Run `docker-compose up -d`
- [ ] Watch initial deployment: `docker-compose logs -f`
- [ ] Wait for all images to download (15-30 minutes)
- [ ] Verify all containers started: `docker-compose ps`
- [ ] All services should show "Up" status

### Phase 5: Service Initialization

#### Elasticsearch
- [ ] Wait for Elasticsearch to be healthy (2-3 minutes)
- [ ] Check health: `curl -u elastic:password localhost:9200/_cluster/health`
- [ ] Status should be "green" or "yellow"

#### MongoDB (for Rocket.Chat)
- [ ] Wait for MongoDB to start (1 minute)
- [ ] Initialize replica set:
  ```bash
  docker exec mongodb mongosh --eval \
    "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongodb:27017'}]})"
  ```
- [ ] Verify: `docker exec mongodb mongosh --eval "rs.status()"`

#### Ollama (AI Model)
- [ ] Pull Llama3 model:
  ```bash
  docker exec ollama ollama pull llama3
  ```
- [ ] This takes 5-10 minutes
- [ ] Verify: `docker exec ollama ollama list`
- [ ] Restart AI analyzer: `docker-compose restart ai-analyzer`

#### LDAP
- [ ] Wait for OpenLDAP initialization (1-2 minutes)
- [ ] Test LDAP connection:
  ```bash
  docker exec openldap ldapsearch -x -b "dc=cyberlab,dc=local"
  ```

### Phase 6: Verification

#### Container Health
- [ ] All containers running: `docker-compose ps`
- [ ] No containers restarting
- [ ] Check resource usage: `docker stats`
- [ ] Memory usage < 24GB
- [ ] CPU usage stabilized

#### Web Access
- [ ] Main portal accessible: http://localhost
- [ ] Grafana accessible: http://localhost:3000
- [ ] Kibana accessible: http://localhost:5601
- [ ] Wazuh accessible: http://localhost:5602
- [ ] TheHive accessible: http://localhost:9000
- [ ] Rocket.Chat accessible: http://localhost:3100

#### Login Tests
- [ ] Grafana login works (admin + password from .env)
- [ ] Kibana login works (elastic + password from .env)
- [ ] Wazuh login works (admin + password from .env)
- [ ] TheHive login works (admin@thehive.local / secret)
- [ ] Rocket.Chat setup wizard appears

#### Service Connectivity
- [ ] Nginx can reach backend services
- [ ] Elasticsearch accepting data
- [ ] Logstash processing logs
- [ ] Wazuh receiving events
- [ ] AI analyzer running cycles
- [ ] Grafana showing metrics

### Phase 7: Initial Configuration

#### Grafana
- [ ] Login to Grafana
- [ ] Change admin password
- [ ] Add Prometheus data source (http://prometheus:9090)
- [ ] Import security dashboard from `dashboards/security-overview.json`
- [ ] Verify dashboard shows data

#### Kibana
- [ ] Login to Kibana
- [ ] Create index pattern: `filebeat-*`
- [ ] Set time field: `@timestamp`
- [ ] Verify logs appearing in Discover

#### Wazuh
- [ ] Login to Wazuh dashboard
- [ ] Verify Wazuh manager is connected
- [ ] Check agents (should show manager itself)
- [ ] Review initial alerts

#### Rocket.Chat
- [ ] Complete setup wizard
- [ ] Create admin account
- [ ] Configure workspace name
- [ ] Optional: Configure webhook for alerts

#### LDAP
- [ ] Login to phpLDAPadmin (http://localhost:6443)
- [ ] Browse directory structure
- [ ] Create test user account
- [ ] Test user login in Grafana (if LDAP integration enabled)

## Post-Deployment

### Security Hardening
- [ ] Change all default passwords in `.env`
- [ ] Generate new SSL certificates (replace self-signed)
- [ ] Configure firewall rules in OPNsense
- [ ] Set up VPN access (WireGuard or OpenVPN)
- [ ] Create LDAP user accounts for team
- [ ] Configure RADIUS policies
- [ ] Enable 2FA on critical services
- [ ] Review and tune Suricata rules

### Monitoring Setup
- [ ] Configure email notifications in Grafana
- [ ] Set up alerting rules in Prometheus
- [ ] Configure Wazuh alert destinations
- [ ] Set up Rocket.Chat webhook for security alerts
- [ ] Test alert delivery
- [ ] Create custom dashboards in Grafana
- [ ] Set up log retention policies

### Backup Configuration
- [ ] Verify backup service running
- [ ] Test manual backup: `docker exec backup /usr/local/bin/backup.sh`
- [ ] Verify backup repository: `docker exec backup restic -r /backup-repo snapshots`
- [ ] Configure backup schedule (default: 2 AM daily)
- [ ] Test restore procedure
- [ ] Set up offsite backup destination (optional)

### Documentation
- [ ] Document custom configurations
- [ ] Record all passwords in password manager
- [ ] Create network diagram for your setup
- [ ] Document any deviations from defaults
- [ ] Create runbook for common tasks
- [ ] Document incident response procedures

### Testing
- [ ] Test VPN connectivity
- [ ] Test user authentication (LDAP)
- [ ] Simulate security event (IDS alert)
- [ ] Verify alert pipeline works
- [ ] Test incident creation in TheHive
- [ ] Verify AI analyzer detects anomalies
- [ ] Test backup and restore
- [ ] Test service restart procedures

## Ongoing Maintenance

### Daily
- [ ] Check Grafana dashboard for anomalies
- [ ] Review high-severity alerts in Wazuh
- [ ] Monitor resource usage
- [ ] Check for container failures

### Weekly
- [ ] Review security logs in Kibana
- [ ] Check backup status
- [ ] Review AI analyzer insights
- [ ] Update threat intelligence feeds (if configured)
- [ ] Clean old log indices (if needed)

### Monthly
- [ ] Update container images: `./scripts/update-all.sh`
- [ ] Review and tune IDS rules
- [ ] Performance optimization
- [ ] Review and update firewall rules
- [ ] Security assessment
- [ ] Documentation updates

### Quarterly
- [ ] Full security audit
- [ ] Disaster recovery drill
- [ ] Compliance review
- [ ] Performance benchmarking
- [ ] Architecture review

## Troubleshooting Checklist

If something goes wrong:

- [ ] Check `docker-compose ps` for failed containers
- [ ] Review logs: `docker-compose logs <service>`
- [ ] Check resource usage: `docker stats`
- [ ] Verify disk space: `df -h`
- [ ] Check network connectivity between containers
- [ ] Review firewall logs
- [ ] Consult [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Rollback Procedure

If deployment fails:

- [ ] Stop all services: `docker-compose down`
- [ ] Review logs to identify issue
- [ ] Fix configuration
- [ ] Clean up if needed: `docker system prune`
- [ ] Re-deploy: `docker-compose up -d`

## Success Criteria

Deployment is successful when:

- ✅ All 32 containers running and healthy
- ✅ All web interfaces accessible
- ✅ Authentication working (LDAP)
- ✅ Logs flowing to Elasticsearch
- ✅ Dashboards showing data
- ✅ AI analyzer running analysis cycles
- ✅ Alerts being generated and displayed
- ✅ Backup running successfully
- ✅ No containers constantly restarting
- ✅ Resource usage within limits (< 24GB RAM)

## Quick Reference

### Essential Commands
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Restart service
docker-compose restart <service>

# Update all
./scripts/update-all.sh

# Backup
docker exec backup /usr/local/bin/backup.sh
```

### Key URLs
- Main Portal: http://localhost
- Grafana: http://localhost:3000
- Kibana: http://localhost:5601
- Wazuh: http://localhost:5602
- TheHive: http://localhost:9000

### Get Help
- Documentation: `/docs` directory
- Troubleshooting: `docs/TROUBLESHOOTING.md`
- Architecture: `docs/ARCHITECTURE.md`
- Network Design: `docs/NETWORK_DESIGN.md`

---

## Sign-Off

### Deployed By: ___________________
### Date: ___________________
### Version: 1.0
### Notes: ___________________

**Next Review Date**: ___________________

---

*Keep this checklist for future deployments and maintenance activities*
