#!/bin/bash
# Generate secrets and certificates for the infrastructure

set -e

echo "=================================================="
echo "Generating Secrets and Certificates"
echo "=================================================="

# Generate random passwords
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Create .env file
echo "[*] Creating .env file with secure passwords..."
cat > .env << EOF
# Generated on $(date)
# Cybersecurity Infrastructure Environment Variables

# Elasticsearch
ELASTIC_PASSWORD=$(generate_password)

# PostgreSQL
POSTGRES_PASSWORD=$(generate_password)

# LDAP
LDAP_ORGANISATION=CyberLab
LDAP_DOMAIN=cyberlab.local
LDAP_ADMIN_PASSWORD=$(generate_password)
LDAP_CONFIG_PASSWORD=$(generate_password)

# Wazuh
WAZUH_INDEXER_PASSWORD=$(generate_password)
WAZUH_API_PASSWORD=$(generate_password)
WAZUH_DASHBOARD_PASSWORD=$(generate_password)

# Grafana
GRAFANA_USER=admin
GRAFANA_PASSWORD=$(generate_password)

# Rocket.Chat
ROCKETCHAT_PASSWORD=$(generate_password)
ROCKETCHAT_WEBHOOK_URL=

# Backup
BACKUP_PASSWORD=$(generate_password)

# Network Configuration
EXTERNAL_NET=172.20.0.0/24
DMZ_NET=172.20.10.0/24
INTERNAL_NET=172.20.20.0/24
SECURITY_NET=172.20.30.0/24
MANAGEMENT_NET=172.20.40.0/24
EOF

chmod 600 .env

echo "[*] Generating SSL certificates for Nginx..."
mkdir -p configs/nginx/certs
mkdir -p data/certs

# Generate self-signed certificate for Nginx
if [ ! -f configs/nginx/certs/server.key ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout configs/nginx/certs/server.key \
        -out configs/nginx/certs/server.crt \
        -subj "/C=AU/ST=NSW/L=Sydney/O=CyberLab/CN=cyberlab.local"
    echo "✓ Nginx SSL certificate generated"
else
    echo "✓ Nginx SSL certificate already exists"
fi

# Generate certificates for LDAP
echo "[*] Generating SSL certificates for LDAP..."
mkdir -p configs/ldap/certs

if [ ! -f configs/ldap/certs/ldap.key ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout configs/ldap/certs/ldap.key \
        -out configs/ldap/certs/ldap.crt \
        -subj "/C=AU/ST=NSW/L=Sydney/O=CyberLab/CN=ldap.cyberlab.local"
    echo "✓ LDAP SSL certificate generated"
else
    echo "✓ LDAP SSL certificate already exists"
fi

# Create WireGuard configuration directory
echo "[*] Creating WireGuard configuration..."
mkdir -p configs/wireguard
cat > configs/wireguard/wg0.conf << 'EOF'
[Interface]
Address = 10.13.13.1/24
ListenPort = 51820
PrivateKey = <GENERATE_AFTER_FIRST_RUN>

# Add peer configurations here after deployment
EOF

# Create OpenVPN configuration directory
echo "[*] Creating OpenVPN configuration..."
mkdir -p configs/openvpn

# Initialize Suricata rules directory
echo "[*] Creating Suricata rules directory..."
mkdir -p configs/suricata/rules

# Create initial LDAP schema
echo "[*] Creating LDAP initial configuration..."
mkdir -p configs/ldap/bootstrap
cat > configs/ldap/bootstrap/init.ldif << 'EOF'
dn: ou=people,dc=cyberlab,dc=local
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=cyberlab,dc=local
objectClass: organizationalUnit
ou: groups

dn: cn=admins,ou=groups,dc=cyberlab,dc=local
objectClass: groupOfNames
cn: admins
member: cn=admin,dc=cyberlab,dc=local

dn: cn=editors,ou=groups,dc=cyberlab,dc=local
objectClass: groupOfNames
cn: editors
member: cn=admin,dc=cyberlab,dc=local

dn: cn=viewers,ou=groups,dc=cyberlab,dc=local
objectClass: groupOfNames
cn: viewers
member: cn=admin,dc=cyberlab,dc=local

# Default admin user
dn: cn=secadmin,ou=people,dc=cyberlab,dc=local
objectClass: inetOrgPerson
cn: secadmin
sn: Administrator
givenName: Security
mail: admin@cyberlab.local
userPassword: changeme
EOF

# Create TheHive configuration
echo "[*] Creating TheHive configuration..."
cat > configs/thehive/application.conf << 'EOF'
play.http.secret.key="$(openssl rand -hex 32)"

db {
  provider = janusgraph
  janusgraph {
    storage {
      backend = berkeleyje
      directory = /opt/thp/thehive/database
    }
    index.search {
      backend = lucene
      directory = /opt/thp/thehive/index
    }
  }
}

storage {
  provider = localfs
  localfs.location = /opt/thp/thehive/data
}

play.modules.enabled += org.thp.thehive.connector.cortex.CortexModule
cortex {
  servers = [
    {
      name = local
      url = "http://cortex:9001"
      auth {
        type = "bearer"
        key = "$(openssl rand -hex 32)"
      }
    }
  ]
}
EOF

# Create Cortex configuration
echo "[*] Creating Cortex configuration..."
cat > configs/cortex/application.conf << 'EOF'
play.http.secret.key="$(openssl rand -hex 32)"

analyzer {
  urls = []
}

responder {
  urls = []
}

job {
  directory = /tmp/cortex-jobs
}

docker {
  job {
    directory = /tmp/cortex-jobs
  }
  container {
    capAdd = ["SYS_PTRACE"]
  }
}
EOF

# Create Elasticsearch configuration
echo "[*] Creating Elasticsearch configuration..."
cat > configs/elasticsearch/elasticsearch.yml << 'EOF'
cluster.name: cyberlab-cluster
node.name: elasticsearch
network.host: 0.0.0.0

xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false

discovery.type: single-node
EOF

# Create Kibana configuration
echo "[*] Creating Kibana configuration..."
cat > configs/kibana/kibana.yml << 'EOF'
server.name: kibana
server.host: 0.0.0.0
elasticsearch.hosts: ["http://elasticsearch:9200"]
monitoring.ui.container.elasticsearch.enabled: true

xpack.security.enabled: true
xpack.encryptedSavedObjects.encryptionKey: "$(openssl rand -hex 32)"
EOF

echo "[*] Setting permissions..."
chmod 644 configs/nginx/certs/*
chmod 644 configs/ldap/certs/*
chmod 755 configs/wireguard
chmod 755 configs/openvpn

echo ""
echo "=================================================="
echo "✅ Secrets and certificates generated successfully!"
echo "=================================================="
echo ""
echo "⚠️  IMPORTANT: Passwords have been saved to .env file"
echo "    Keep this file secure and NEVER commit it to version control"
echo ""
echo "📝 Generated files:"
echo "   - .env (environment variables)"
echo "   - configs/nginx/certs/ (SSL certificates)"
echo "   - configs/ldap/certs/ (LDAP certificates)"
echo "   - configs/thehive/application.conf"
echo "   - configs/cortex/application.conf"
echo ""
echo "Next step: docker-compose up -d"
echo ""
