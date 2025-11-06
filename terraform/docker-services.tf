# Docker-based Services
# These services are deployed as containers when not using VMs

# Data volumes for persistent storage
resource "docker_volume" "wazuh_manager_data" {
  name = "${var.project_name}-wazuh-manager-data"
}

resource "docker_volume" "wazuh_indexer_data" {
  name = "${var.project_name}-wazuh-indexer-data"
}

resource "docker_volume" "wazuh_dashboard_data" {
  name = "${var.project_name}-wazuh-dashboard-data"
}

resource "docker_volume" "nginx_config" {
  name = "${var.project_name}-nginx-config"
}

resource "docker_volume" "wireguard_config" {
  name = "${var.project_name}-wireguard-config"
}

# NGINX Reverse Proxy (DMZ Layer)
resource "docker_container" "nginx" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name  = "${var.project_name}-nginx"
  image = docker_image.nginx[0].image_id

  networks_advanced {
    name = docker_network.dmz[0].name
    ipv4_address = cidrhost(var.dmz_subnet, 10)
  }

  networks_advanced {
    name = docker_network.internal[0].name
    ipv4_address = cidrhost(var.internal_subnet, 10)
  }

  ports {
    internal = 80
    external = var.nginx_http_port
  }

  ports {
    internal = 443
    external = var.nginx_https_port
  }

  volumes {
    volume_name    = docker_volume.nginx_config.name
    container_path = "/etc/nginx/conf.d"
  }

  restart = "unless-stopped"

  labels {
    label = "layer"
    value = "dmz"
  }

  labels {
    label = "service"
    value = "reverse-proxy"
  }
}

resource "docker_image" "nginx" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1
  name  = var.nginx_image
}

# WireGuard VPN (DMZ Layer)
resource "docker_container" "wireguard" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name  = "${var.project_name}-wireguard"
  image = docker_image.wireguard[0].image_id

  networks_advanced {
    name = docker_network.dmz[0].name
    ipv4_address = cidrhost(var.dmz_subnet, 20)
  }

  networks_advanced {
    name = docker_network.management[0].name
    ipv4_address = cidrhost(var.management_subnet, 20)
  }

  ports {
    internal = var.wireguard_port
    external = var.wireguard_port
    protocol = "udp"
  }

  volumes {
    volume_name    = docker_volume.wireguard_config.name
    container_path = "/config"
  }

  env = [
    "PUID=1000",
    "PGID=1000",
    "TZ=UTC",
    "SERVERURL=auto",
    "SERVERPORT=${var.wireguard_port}",
    "PEERS=${var.wireguard_peers}",
    "PEERDNS=auto",
    "INTERNAL_SUBNET=${var.management_subnet}",
    "ALLOWEDIPS=0.0.0.0/0"
  ]

  capabilities {
    add = ["NET_ADMIN", "SYS_MODULE"]
  }

  sysctls = {
    "net.ipv4.conf.all.src_valid_mark" = "1"
  }

  restart = "unless-stopped"

  labels {
    label = "layer"
    value = "dmz"
  }

  labels {
    label = "service"
    value = "vpn"
  }
}

resource "docker_image" "wireguard" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1
  name  = "linuxserver/wireguard:latest"
}

# Wazuh Manager (Internal Layer)
resource "docker_container" "wazuh_manager" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name  = "${var.project_name}-wazuh-manager"
  image = docker_image.wazuh_manager[0].image_id

  networks_advanced {
    name = docker_network.internal[0].name
    ipv4_address = cidrhost(var.internal_subnet, 30)
  }

  networks_advanced {
    name = docker_network.management[0].name
    ipv4_address = cidrhost(var.management_subnet, 30)
  }

  ports {
    internal = var.wazuh_registration_port
    external = var.wazuh_registration_port
  }

  ports {
    internal = var.wazuh_cluster_port
    external = var.wazuh_cluster_port
  }

  ports {
    internal = var.wazuh_api_port
    external = var.wazuh_api_port
  }

  volumes {
    volume_name    = docker_volume.wazuh_manager_data.name
    container_path = "/var/ossec/data"
  }

  env = [
    "INDEXER_URL=https://${cidrhost(var.internal_subnet, 40)}:9200",
    "INDEXER_USERNAME=admin",
    "INDEXER_PASSWORD=SecurePassword123!",
    "FILEBEAT_SSL_VERIFICATION_MODE=full",
    "SSL_CERTIFICATE_AUTHORITIES=/etc/ssl/root-ca.pem",
    "SSL_CERTIFICATE=/etc/ssl/filebeat.pem",
    "SSL_KEY=/etc/ssl/filebeat.key"
  ]

  restart = "unless-stopped"

  labels {
    label = "layer"
    value = "internal"
  }

  labels {
    label = "service"
    value = "siem-manager"
  }
}

resource "docker_image" "wazuh_manager" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1
  name  = "wazuh/wazuh-manager:${var.wazuh_version}"
}

# Wazuh Indexer (Secure Layer)
resource "docker_container" "wazuh_indexer" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name  = "${var.project_name}-wazuh-indexer"
  image = docker_image.wazuh_indexer[0].image_id

  networks_advanced {
    name = docker_network.internal[0].name
    ipv4_address = cidrhost(var.internal_subnet, 40)
  }

  networks_advanced {
    name = docker_network.secure[0].name
    ipv4_address = cidrhost(var.secure_subnet, 40)
  }

  volumes {
    volume_name    = docker_volume.wazuh_indexer_data.name
    container_path = "/var/lib/wazuh-indexer"
  }

  env = [
    "OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g",
    "bootstrap.memory_lock=true",
    "discovery.type=single-node",
    "network.host=0.0.0.0",
    "plugins.security.ssl.http.enabled=true",
    "plugins.security.ssl.transport.enabled=true"
  ]

  ulimit {
    name = "memlock"
    soft = -1
    hard = -1
  }

  ulimit {
    name = "nofile"
    soft = 65536
    hard = 65536
  }

  restart = "unless-stopped"

  labels {
    label = "layer"
    value = "secure"
  }

  labels {
    label = "service"
    value = "indexer"
  }
}

resource "docker_image" "wazuh_indexer" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1
  name  = "wazuh/wazuh-indexer:${var.wazuh_version}"
}

# Wazuh Dashboard (Management Layer)
resource "docker_container" "wazuh_dashboard" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name  = "${var.project_name}-wazuh-dashboard"
  image = docker_image.wazuh_dashboard[0].image_id

  networks_advanced {
    name = docker_network.internal[0].name
    ipv4_address = cidrhost(var.internal_subnet, 50)
  }

  networks_advanced {
    name = docker_network.management[0].name
    ipv4_address = cidrhost(var.management_subnet, 50)
  }

  ports {
    internal = 443
    external = 5601
  }

  volumes {
    volume_name    = docker_volume.wazuh_dashboard_data.name
    container_path = "/usr/share/wazuh-dashboard/data"
  }

  env = [
    "INDEXER_USERNAME=admin",
    "INDEXER_PASSWORD=SecurePassword123!",
    "WAZUH_API_URL=https://${cidrhost(var.internal_subnet, 30)}",
    "API_USERNAME=wazuh-wui",
    "API_PASSWORD=MyS3cr37P450r.*-"
  ]

  depends_on = [
    docker_container.wazuh_indexer,
    docker_container.wazuh_manager
  ]

  restart = "unless-stopped"

  labels {
    label = "layer"
    value = "management"
  }

  labels {
    label = "service"
    value = "dashboard"
  }
}

resource "docker_image" "wazuh_dashboard" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1
  name  = "wazuh/wazuh-dashboard:${var.wazuh_version}"
}

# Outputs
output "docker_services" {
  description = "Docker service endpoints"
  value = {
    nginx = {
      http  = "http://localhost:${var.nginx_http_port}"
      https = "https://localhost:${var.nginx_https_port}"
    }
    wireguard = {
      port        = var.wireguard_port
      config_path = try(docker_volume.wireguard_config.name, null)
    }
    wazuh = {
      dashboard = "https://localhost:5601"
      api       = "https://localhost:${var.wazuh_api_port}"
      manager   = "localhost:${var.wazuh_registration_port}"
    }
  }
}
