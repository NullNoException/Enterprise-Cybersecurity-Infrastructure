#!/bin/bash
# Initialize directory structure for the cybersecurity infrastructure

set -e

echo "=================================================="
echo "Initializing Cybersecurity Infrastructure"
echo "=================================================="

# Create base directories
echo "[*] Creating configuration directories..."
mkdir -p configs/{nginx/conf.d,logstash/pipeline,suricata,wazuh,opnsense,wireguard,openvpn,ldap/certs,radius,grafana,prometheus/alerts,thehive,cortex,filebeat,kibana,elasticsearch}
mkdir -p scripts
mkdir -p ai-analyzer
mkdir -p dashboards
mkdir -p web
mkdir -p docs
mkdir -p data/{backups,logs,certs}

# Create web content directory
echo "[*] Creating web content..."
mkdir -p web/{html,images,assets}

# Create placeholder index.html
cat > web/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CyberLab Security Infrastructure</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: white;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
        }
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 40px;
        }
        .service {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            border-radius: 10px;
            transition: transform 0.3s;
        }
        .service:hover {
            transform: translateY(-5px);
        }
        a {
            color: white;
            text-decoration: none;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ CyberLab Security Infrastructure</h1>
        <p>Enterprise-Grade Cybersecurity Monitoring & Defense Platform</p>

        <div class="services">
            <div class="service">
                <h3>📊 Grafana</h3>
                <a href="/grafana" target="_blank">Monitoring Dashboard</a>
            </div>
            <div class="service">
                <h3>🔍 Kibana</h3>
                <a href="/kibana" target="_blank">Log Analytics</a>
            </div>
            <div class="service">
                <h3>🛡️ Wazuh</h3>
                <a href="/wazuh" target="_blank">SIEM Console</a>
            </div>
            <div class="service">
                <h3>🔎 TheHive</h3>
                <a href="/thehive" target="_blank">Incident Response</a>
            </div>
            <div class="service">
                <h3>💬 Rocket.Chat</h3>
                <a href="/chat" target="_blank">Team Communication</a>
            </div>
            <div class="service">
                <h3>🏥 Health Check</h3>
                <a href="/health" target="_blank">System Status</a>
            </div>
        </div>
    </div>
</body>
</html>
EOF

echo "[*] Setting permissions..."
chmod -R 755 configs
chmod -R 755 scripts
chmod -R 755 web

echo ""
echo "=================================================="
echo "✅ Directory structure initialized successfully!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Run: ./scripts/generate-secrets.sh"
echo "2. Review and customize .env file"
echo "3. Run: docker-compose up -d"
echo ""
