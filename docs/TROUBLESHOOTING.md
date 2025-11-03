# Troubleshooting Guide

## Quick Diagnostics

### Check Overall System Health

```bash
# Check all container status
docker-compose ps

# View resource usage
docker stats

# Check Docker system info
docker system df

# View recent logs across all services
docker-compose logs --tail=50
```

## Common Issues & Solutions

### 1. Containers Not Starting

#### Issue: Container exits immediately after starting

**Symptoms:**
```bash
docker-compose ps
# Shows: Exit 1, Exit 137, or Restarting
```

**Diagnosis:**
```bash
# Check container logs
docker-compose logs <service-name>

# Check exit code
docker inspect <container-name> | grep ExitCode
```

**Common Causes & Solutions:**

**Exit Code 137** (Out of Memory):
```bash
# Solution: Increase Docker Desktop memory
# Settings → Resources → Memory: 24GB+

# Or reduce service memory limits in docker-compose.yml
```

**Exit Code 1** (Configuration Error):
```bash
# Check configuration syntax
docker-compose config

# Verify .env file exists
ls -la .env

# Check file permissions
chmod 600 .env
```

**Permission Denied**:
```bash
# Fix volume permissions
sudo chown -R 1000:1000 data/
chmod -R 755 configs/
```

### 2. Elasticsearch Issues

#### Issue: Elasticsearch cluster health is RED or YELLOW

**Check Health:**
```bash
curl -u elastic:$(grep ELASTIC_PASSWORD .env | cut -d= -f2) \
  http://localhost:9200/_cluster/health?pretty
```

**Solution 1: Insufficient Memory**
```bash
# Check ES logs
docker logs elasticsearch

# Look for: "OutOfMemoryError" or "heap size"

# Increase heap in docker-compose.yml:
# ES_JAVA_OPTS: "-Xms4g -Xmx4g"

# Restart
docker-compose restart elasticsearch
```

**Solution 2: Unassigned Shards**
```bash
# Check shards
curl -u elastic:password http://localhost:9200/_cat/shards?v

# Reallocate unassigned shards
curl -u elastic:password -X POST \
  http://localhost:9200/_cluster/reroute?retry_failed=true
```

**Solution 3: Disk Space**
```bash
# Check disk usage
df -h

# Clean old indices
curl -u elastic:password -X DELETE \
  "localhost:9200/filebeat-2024.01.*"

# Enable auto-cleanup
curl -u elastic:password -X PUT \
  "localhost:9200/_cluster/settings" \
  -H 'Content-Type: application/json' -d'
{
  "transient": {
    "cluster.routing.allocation.disk.watermark.low": "85%",
    "cluster.routing.allocation.disk.watermark.high": "90%"
  }
}'
```

### 3. VPN Connection Issues

#### Issue: Can't connect to VPN

**WireGuard Troubleshooting:**
```bash
# Check WireGuard is running
docker logs wireguard

# Verify configuration exists
docker exec wireguard ls -la /config

# Generate new peer
docker exec wireguard /app/add-peer <peer-name>

# Get configuration
docker exec wireguard cat /config/peer_<peer-name>/peer_<peer-name>.conf
```

**OpenVPN Troubleshooting:**
```bash
# Check OpenVPN status
docker logs openvpn

# Verify server is listening
netstat -an | grep 1194

# Check certificate validity
docker exec openvpn ovpn_getclient <client-name>
```

### 4. LDAP Authentication Failures

#### Issue: Services can't authenticate against LDAP

**Diagnosis:**
```bash
# Check LDAP is running
docker logs openldap

# Test LDAP connection
docker exec openldap ldapsearch -x -H ldap://localhost \
  -b "dc=cyberlab,dc=local" -D "cn=admin,dc=cyberlab,dc=local" \
  -w $(grep LDAP_ADMIN_PASSWORD .env | cut -d= -f2)
```

**Common Solutions:**

**LDAP Not Ready:**
```bash
# Wait for initialization (can take 1-2 minutes)
sleep 120

# Check if directory is populated
docker exec openldap ldapsearch -x -b "dc=cyberlab,dc=local" | grep dn:
```

**Wrong Credentials:**
```bash
# Verify password in .env
grep LDAP_ADMIN_PASSWORD .env

# Reset LDAP admin password
docker-compose down openldap
docker volume rm $(docker volume ls -q | grep openldap)
docker-compose up -d openldap
```

**Service Can't Reach LDAP:**
```bash
# Test connectivity
docker exec grafana ping -c 3 openldap

# Check network
docker network inspect cyberlab_internal_net | grep -A 10 openldap
```

### 5. AI Analyzer Not Working

#### Issue: AI Analyzer not generating analyses

**Check Status:**
```bash
# View analyzer logs
docker logs ai-analyzer -f

# Check if Ollama is accessible
docker exec ai-analyzer curl -s http://ollama:11434/api/tags
```

**Common Issues:**

**Llama3 Model Not Downloaded:**
```bash
# Check available models
docker exec ollama ollama list

# Pull model manually
docker exec ollama ollama pull llama3

# Restart analyzer
docker-compose restart ai-analyzer
```

**Elasticsearch Connection Failed:**
```bash
# Test ES connectivity from analyzer
docker exec ai-analyzer curl -s http://elasticsearch:9200

# Check credentials
docker exec ai-analyzer env | grep ELASTIC

# Update password in docker-compose.yml if needed
```

**Out of Memory:**
```bash
# Check Ollama memory
docker stats ollama

# Reduce model size or increase Docker memory
# Alternatively, use smaller model:
docker exec ollama ollama pull llama2
```

### 6. Wazuh Issues

#### Issue: Wazuh agents not connecting

**Check Manager:**
```bash
# View Wazuh logs
docker logs wazuh

# Check agent status
docker exec wazuh /var/ossec/bin/agent_control -l
```

**Solution:**
```bash
# Get manager IP
docker inspect wazuh | grep IPAddress

# On agent, update configuration
# Edit /var/ossec/etc/ossec.conf with correct IP

# Restart agent
systemctl restart wazuh-agent
```

#### Issue: Wazuh dashboard not accessible

**Diagnosis:**
```bash
# Check dashboard logs
docker logs wazuh-dashboard

# Verify API connectivity
curl -k -u wazuh-wui:password https://localhost:55000/
```

**Solution:**
```bash
# Restart dashboard
docker-compose restart wazuh-dashboard

# Check API credentials in docker-compose.yml
# Ensure WAZUH_API_PASSWORD matches between wazuh and wazuh-dashboard
```

### 7. Network Connectivity Issues

#### Issue: Containers can't communicate

**Diagnosis:**
```bash
# Check if containers are on same network
docker inspect <container1> | grep -A 20 Networks
docker inspect <container2> | grep -A 20 Networks

# Test ping
docker exec <container1> ping -c 3 <container2>

# Test DNS resolution
docker exec <container1> nslookup <container2>
```

**Solutions:**

**Different Networks:**
```bash
# Verify network configuration in docker-compose.yml
# Ensure both services list the required network

# Recreate networks
docker-compose down
docker network prune
docker-compose up -d
```

**Firewall Blocking:**
```bash
# Check OPNsense logs
docker logs opnsense | grep -i block

# Temporarily disable firewall for testing
docker-compose stop opnsense

# If it works, adjust firewall rules
```

**DNS Issues:**
```bash
# Check Docker DNS
docker exec <container> cat /etc/resolv.conf

# Restart Docker DNS
docker-compose down
docker-compose up -d
```

### 8. Performance Issues

#### Issue: System is slow or unresponsive

**Check Resource Usage:**
```bash
# Overall system
docker stats

# Disk usage
docker system df

# Network usage
docker exec cadvisor curl -s localhost:8080/metrics | grep network
```

**Solutions:**

**High CPU:**
```bash
# Identify culprit
docker stats --no-stream | sort -k3 -h

# Reduce resources for non-critical services
# Edit docker-compose.yml, adjust cpus: value

# Disable non-essential services
docker-compose stop tpot cortex
```

**High Memory:**
```bash
# Check memory-hungry services
docker stats --format "table {{.Name}}\t{{.MemUsage}}"

# Reduce Elasticsearch heap
# In docker-compose.yml: ES_JAVA_OPTS: "-Xms2g -Xmx2g"

# Clear caches
docker exec elasticsearch curl -X POST localhost:9200/_cache/clear
```

**Disk Full:**
```bash
# Check disk space
df -h

# Clean Docker system
docker system prune -a --volumes

# Remove old logs
docker exec elasticsearch curl -X DELETE localhost:9200/filebeat-*-2024.01.*
docker exec elasticsearch curl -X DELETE localhost:9200/logstash-*-2024.01.*

# Clean old images
docker image prune -a
```

### 9. Log Collection Issues

#### Issue: Logs not appearing in Kibana

**Check Pipeline:**
```bash
# 1. Check Filebeat
docker logs filebeat | grep -i error

# 2. Check Logstash
docker logs logstash | grep -i error

# 3. Check Elasticsearch
curl -u elastic:password http://localhost:9200/_cat/indices?v
```

**Solutions:**

**Filebeat Not Running:**
```bash
# Restart Filebeat
docker-compose restart filebeat

# Check configuration
docker exec filebeat filebeat test config
docker exec filebeat filebeat test output
```

**Logstash Pipeline Error:**
```bash
# Check pipeline config
docker exec logstash cat /usr/share/logstash/pipeline/main.conf

# Test configuration
docker-compose restart logstash

# View pipeline stats
curl localhost:9600/_node/stats/pipelines?pretty
```

**No Indices Created:**
```bash
# Manually create index
curl -u elastic:password -X PUT "localhost:9200/test-index"

# Check index patterns in Kibana
# Kibana → Management → Index Patterns
```

### 10. Backup & Restore Issues

#### Issue: Backup failing

**Diagnosis:**
```bash
# Check backup logs
docker logs backup

# Verify Restic repository
docker exec backup restic -r /backup-repo snapshots
```

**Solutions:**

**Repository Not Initialized:**
```bash
# Initialize repository
docker exec backup restic -r /backup-repo init
```

**Permission Errors:**
```bash
# Fix volume permissions
docker exec backup chmod -R 755 /backup-source
```

**Out of Space:**
```bash
# Check space
docker exec backup df -h /backup-repo

# Prune old backups
docker exec backup restic -r /backup-repo forget --keep-last 7 --prune
```

## Emergency Procedures

### Complete System Reset

**⚠️ WARNING: This deletes ALL data!**

```bash
# Stop all containers
docker-compose down

# Remove all volumes (DELETES ALL DATA)
docker-compose down -v

# Remove networks
docker network prune -f

# Clean system
docker system prune -a --volumes -f

# Re-initialize
./scripts/init-directories.sh
./scripts/generate-secrets.sh
docker-compose up -d
```

### Restore from Backup

```bash
# Stop services
docker-compose down

# List available snapshots
docker exec backup restic -r /backup-repo snapshots

# Restore specific snapshot
docker exec backup restic -r /backup-repo restore <snapshot-id> \
  --target /restore

# Copy restored data to volumes
docker volume create elasticsearch_data
docker run --rm -v elasticsearch_data:/data -v /restore:/backup \
  alpine cp -r /backup/elasticsearch/* /data/

# Restart services
docker-compose up -d
```

### Service-Specific Restarts

```bash
# Restart single service
docker-compose restart <service-name>

# Restart security stack
docker-compose restart elasticsearch kibana wazuh wazuh-dashboard

# Restart monitoring stack
docker-compose restart prometheus grafana

# Restart with rebuild
docker-compose up -d --build --force-recreate <service-name>
```

## Monitoring & Diagnostics Tools

### Real-Time Monitoring

```bash
# Live container logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f elasticsearch

# Resource monitoring
docker stats

# Network connections
docker exec <container> netstat -an
```

### Health Checks

```bash
# Elasticsearch
curl -u elastic:password localhost:9200/_cluster/health?pretty

# Kibana
curl localhost:5601/api/status

# Wazuh
curl -k -u wazuh-wui:password https://localhost:55000/

# Grafana
curl localhost:3000/api/health

# Prometheus
curl localhost:9090/-/healthy
```

### Debugging Containers

```bash
# Access container shell
docker exec -it <container-name> sh

# Or bash if available
docker exec -it <container-name> bash

# View environment variables
docker exec <container-name> env

# Check network interfaces
docker exec <container-name> ip addr

# Test connectivity
docker exec <container-name> ping -c 3 google.com
```

## Getting Help

### Log Collection for Support

```bash
# Collect all logs
docker-compose logs > cyberlab-logs-$(date +%Y%m%d).txt

# Collect system info
docker info > system-info.txt
docker-compose ps >> system-info.txt
docker stats --no-stream >> system-info.txt

# Create support bundle
tar -czf cyberlab-support-$(date +%Y%m%d).tar.gz \
  cyberlab-logs-*.txt \
  system-info.txt \
  docker-compose.yml \
  .env.template
```

### Useful Documentation

- **Docker Compose**: https://docs.docker.com/compose/
- **Wazuh**: https://documentation.wazuh.com/
- **Elasticsearch**: https://www.elastic.co/guide/
- **Grafana**: https://grafana.com/docs/
- **Suricata**: https://suricata.readthedocs.io/

### Community Resources

- Docker Community Forums
- Wazuh Google Groups
- Elastic Stack Discuss
- Reddit: r/docker, r/cybersecurity

---

Remember: When in doubt, check the logs first with `docker-compose logs <service-name>`!
