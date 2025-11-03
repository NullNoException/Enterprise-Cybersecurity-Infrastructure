# Quick Start Guide

Get the CyberLab security infrastructure running in under 30 minutes!

## Prerequisites

- Windows 10/11 with WSL2
- Docker Desktop installed
- 32GB RAM, 4 CPU cores
- 200GB free disk space

## 5-Step Deployment

### 1. Prepare Environment

```bash
# In WSL terminal
cd /mnt/c/Users/YourUsername/Documents/CyberSecurity-Diploma/Project

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Initialize

```bash
./scripts/init-directories.sh
```

### 3. Generate Secrets

```bash
./scripts/generate-secrets.sh

# IMPORTANT: Save the passwords from .env file!
cat .env
```

### 4. Deploy

```bash
# Pull images and start all services
docker-compose up -d

# This takes 15-30 minutes on first run
```

### 5. Initialize AI Model

```bash
# Wait for services to start (2-3 minutes)
sleep 180

# Initialize MongoDB for Rocket.Chat
docker exec mongodb mongosh --eval "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongodb:27017'}]})"

# Pull AI model (this may take 5-10 minutes)
docker exec ollama ollama pull llama3

# Restart AI analyzer to load model
docker-compose restart ai-analyzer
```

## Verify Deployment

```bash
# Check all services are running
docker-compose ps

# All services should show "Up"
```

## Access Services

Open your browser and visit:

### Main Portal
- **URL**: http://localhost
- Provides links to all services

### Individual Services

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Grafana Dashboard | http://localhost:3000 | admin | Check .env file |
| Kibana (Logs) | http://localhost:5601 | elastic | Check .env file |
| Wazuh (SIEM) | http://localhost:5602 | admin | Check .env file |
| TheHive (IR) | http://localhost:9000 | admin@thehive.local | secret |
| Rocket.Chat | http://localhost:3100 | Setup on first visit | - |

### Get Passwords

```bash
# View all passwords
grep PASSWORD .env

# Or specific password
grep GRAFANA_PASSWORD .env
```

## Monitor Health

### View All Logs
```bash
docker-compose logs -f
```

### View Specific Service
```bash
docker-compose logs -f grafana
```

### Check Resource Usage
```bash
docker stats
```

## Common First Steps

### 1. Access Grafana Dashboard
1. Open http://localhost:3000
2. Login with admin credentials from `.env`
3. Navigate to Dashboards → Browse
4. Open "CyberLab Security Overview"

### 2. View Security Logs in Kibana
1. Open http://localhost:5601
2. Login with elastic credentials
3. Go to Analytics → Discover
4. Select index pattern: `filebeat-*`

### 3. Check AI Analyzer
```bash
# View AI analyzer logs
docker logs ai-analyzer -f

# Should show analysis cycles every 5 minutes
```

### 4. Setup Rocket.Chat
1. Open http://localhost:3100
2. Create admin account on first visit
3. Configure workspace

## Troubleshooting

### Services Not Starting?
```bash
# Check Docker resources
# Ensure Docker has at least 24GB RAM allocated

# Restart services
docker-compose restart
```

### Elasticsearch Yellow/Red Health?
```bash
# Check cluster health
curl -u elastic:$(grep ELASTIC_PASSWORD .env | cut -d= -f2) \
  http://localhost:9200/_cluster/health?pretty

# Wait 2-3 minutes for initialization
```

### AI Analyzer Not Working?
```bash
# Check if Ollama is ready
docker exec ollama ollama list

# If llama3 is not listed, pull it:
docker exec ollama ollama pull llama3

# Restart analyzer
docker-compose restart ai-analyzer
```

### Container Keeps Restarting?
```bash
# Check logs for the problematic service
docker logs <container-name>

# Common issue: Insufficient memory
# Solution: Increase Docker Desktop memory allocation
```

## Next Steps

1. **Read Full Documentation**
   - [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
   - [Architecture Documentation](docs/ARCHITECTURE.md)

2. **Configure Security**
   - Change default passwords
   - Set up LDAP users
   - Configure firewall rules
   - Enable VPN access

3. **Customize Dashboards**
   - Import additional Grafana dashboards
   - Create custom Kibana visualizations
   - Configure Wazuh rules

4. **Set Up Monitoring**
   - Configure alert notifications
   - Set up email/webhook integrations
   - Test incident response workflows

## Maintenance Commands

### Stop All Services
```bash
docker-compose down
```

### Restart All Services
```bash
docker-compose restart
```

### Update All Services
```bash
./scripts/update-all.sh
```

### View System Status
```bash
docker-compose ps
docker stats
```

### Backup Data
```bash
docker exec backup /usr/local/bin/backup.sh
```

## Resource Optimization Tips

If running low on resources:

1. **Disable Non-Essential Services**
   ```bash
   # Edit docker-compose.yml and comment out:
   # - tpot (honeypot)
   # - cortex (if not using TheHive)
   # - rocketchat + mongodb (if not needed)
   ```

2. **Reduce Elasticsearch Memory**
   ```yaml
   # In docker-compose.yml:
   ES_JAVA_OPTS: "-Xms2g -Xmx2g"  # Instead of 4g
   ```

3. **Limit Log Retention**
   ```bash
   # Delete old indices
   curl -X DELETE "localhost:9200/filebeat-2024.01.*"
   ```

## Getting Help

### Check Service Status
```bash
docker-compose ps
docker-compose logs <service-name>
```

### Inspect Networks
```bash
docker network ls
docker network inspect cyberlab_security_net
```

### Access Container Shell
```bash
docker exec -it <container-name> sh
```

### Full Reset (⚠️ Deletes All Data)
```bash
docker-compose down -v
rm -rf data/
./scripts/init-directories.sh
./scripts/generate-secrets.sh
docker-compose up -d
```

## Success Indicators

You'll know everything is working when:

- ✅ All containers show "Up" status
- ✅ Grafana dashboard loads and shows metrics
- ✅ Kibana shows log entries
- ✅ Wazuh dashboard displays security events
- ✅ AI Analyzer logs show analysis cycles
- ✅ No containers constantly restarting

## Support

For detailed documentation:
- Deployment: [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Main README: [README.md](README.md)

---

**Congratulations!** You now have a fully functional enterprise-grade cybersecurity infrastructure running locally! 🎉
