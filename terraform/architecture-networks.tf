# Network Architecture Implementation
# Based on docs/ARCHITECTURE.md - 5 network segments with defense-in-depth

# VirtualBox Host-Only Networks
# These need to be created before deploying VMs

resource "null_resource" "setup_virtualbox_networks" {
  count = var.deploy_architecture && local.use_virtualbox ? 1 : 0

  # Create External/VPN network (vboxnet0)
  provisioner "local-exec" {
    command = <<-EOT
      # Check if network exists, create if not
      if ! VBoxManage list hostonlyifs | grep -q "vboxnet0"; then
        VBoxManage hostonlyif create
      fi
      VBoxManage hostonlyif ipconfig vboxnet0 --ip 172.25.0.1 --netmask 255.255.255.0
    EOT
  }

  # Create DMZ network (vboxnet1)
  provisioner "local-exec" {
    command = <<-EOT
      if ! VBoxManage list hostonlyifs | grep -q "vboxnet1"; then
        VBoxManage hostonlyif create
      fi
      VBoxManage hostonlyif ipconfig vboxnet1 --ip 172.25.10.1 --netmask 255.255.255.0
    EOT
  }

  # Create Internal network (vboxnet2)
  provisioner "local-exec" {
    command = <<-EOT
      if ! VBoxManage list hostonlyifs | grep -q "vboxnet2"; then
        VBoxManage hostonlyif create
      fi
      VBoxManage hostonlyif ipconfig vboxnet2 --ip 172.25.20.1 --netmask 255.255.255.0
    EOT
  }

  # Create Security network (vboxnet3)
  provisioner "local-exec" {
    command = <<-EOT
      if ! VBoxManage list hostonlyifs | grep -q "vboxnet3"; then
        VBoxManage hostonlyif create
      fi
      VBoxManage hostonlyif ipconfig vboxnet3 --ip 172.25.30.1 --netmask 255.255.255.0
    EOT
  }

  # Create Management network (vboxnet4)
  provisioner "local-exec" {
    command = <<-EOT
      if ! VBoxManage list hostonlyifs | grep -q "vboxnet4"; then
        VBoxManage hostonlyif create
      fi
      VBoxManage hostonlyif ipconfig vboxnet4 --ip 172.25.40.1 --netmask 255.255.255.0
    EOT
  }
}

# Docker Networks for Architecture (when not using VirtualBox)
# These mirror the same network topology using Docker networking

resource "docker_network" "arch_external" {
  count = var.deploy_architecture && !local.use_virtualbox ? 1 : 0

  name   = "${var.project_name}-arch-external"
  driver = "bridge"

  ipam_config {
    subnet  = var.arch_external_subnet
    gateway = cidrhost(var.arch_external_subnet, 1)
  }

  labels {
    label = "layer"
    value = "external"
  }

  labels {
    label = "project"
    value = var.project_name
  }

  labels {
    label = "architecture"
    value = "defense-in-depth"
  }
}

resource "docker_network" "arch_dmz" {
  count = var.deploy_architecture && !local.use_virtualbox ? 1 : 0

  name   = "${var.project_name}-arch-dmz"
  driver = "bridge"

  ipam_config {
    subnet  = var.arch_dmz_subnet
    gateway = cidrhost(var.arch_dmz_subnet, 1)
  }

  labels {
    label = "layer"
    value = "dmz"
  }

  labels {
    label = "project"
    value = var.project_name
  }
}

resource "docker_network" "arch_internal" {
  count = var.deploy_architecture && !local.use_virtualbox ? 1 : 0

  name   = "${var.project_name}-arch-internal"
  driver = "bridge"

  ipam_config {
    subnet  = var.arch_internal_subnet
    gateway = cidrhost(var.arch_internal_subnet, 1)
  }

  labels {
    label = "layer"
    value = "internal"
  }

  labels {
    label = "project"
    value = var.project_name
  }
}

resource "docker_network" "arch_security" {
  count = var.deploy_architecture && !local.use_virtualbox ? 1 : 0

  name   = "${var.project_name}-arch-security"
  driver = "bridge"

  ipam_config {
    subnet  = var.arch_security_subnet
    gateway = cidrhost(var.arch_security_subnet, 1)
  }

  labels {
    label = "layer"
    value = "security"
  }

  labels {
    label = "project"
    value = var.project_name
  }
}

resource "docker_network" "arch_management" {
  count = var.deploy_architecture && !local.use_virtualbox ? 1 : 0

  name   = "${var.project_name}-arch-management"
  driver = "bridge"

  ipam_config {
    subnet  = var.arch_management_subnet
    gateway = cidrhost(var.arch_management_subnet, 1)
  }

  labels {
    label = "layer"
    value = "management"
  }

  labels {
    label = "project"
    value = var.project_name
  }
}

# Output network information
output "architecture_networks" {
  description = "Architecture network topology information"
  value = var.deploy_architecture ? {
    deployment_type = local.use_virtualbox ? "VirtualBox" : "Docker"

    external = {
      subnet    = var.arch_external_subnet
      gateway   = cidrhost(var.arch_external_subnet, 1)
      purpose   = "VPN entry point, external access"
      vboxnet   = "vboxnet0"
      docker_id = try(docker_network.arch_external[0].id, null)
    }

    dmz = {
      subnet    = var.arch_dmz_subnet
      gateway   = cidrhost(var.arch_dmz_subnet, 1)
      purpose   = "Public-facing services (NGINX, T-Pot)"
      vboxnet   = "vboxnet1"
      docker_id = try(docker_network.arch_dmz[0].id, null)
      services  = ["nginx:172.25.10.10", "tpot:172.25.10.50"]
    }

    internal = {
      subnet    = var.arch_internal_subnet
      gateway   = cidrhost(var.arch_internal_subnet, 1)
      purpose   = "Internal services and data"
      vboxnet   = "vboxnet2"
      docker_id = try(docker_network.arch_internal[0].id, null)
      services = [
        "postgresql:172.25.20.30",
        "openldap:172.25.20.40",
        "rocketchat:172.25.20.50",
        "mongodb:172.25.20.51",
        "wazuh-manager:172.25.20.60",
        "freeradius:172.25.20.70"
      ]
    }

    security = {
      subnet    = var.arch_security_subnet
      gateway   = cidrhost(var.arch_security_subnet, 1)
      purpose   = "Security monitoring and analysis"
      vboxnet   = "vboxnet3"
      docker_id = try(docker_network.arch_security[0].id, null)
      services = [
        "elasticsearch:172.25.30.10",
        "kibana:172.25.30.11",
        "wazuh-manager:172.25.30.20",
        "wazuh-dashboard:172.25.30.21",
        "thehive:172.25.30.40",
        "ollama:172.25.30.51",
        "prometheus:172.25.30.60"
      ]
    }

    management = {
      subnet    = var.arch_management_subnet
      gateway   = cidrhost(var.arch_management_subnet, 1)
      purpose   = "Administrative interfaces"
      vboxnet   = "vboxnet4"
      docker_id = try(docker_network.arch_management[0].id, null)
      services = [
        "prometheus:172.25.40.10",
        "grafana:172.25.40.11",
        "backup:172.25.40.30"
      ]
    }

    firewall = {
      vm_name    = try(module.opnsense_firewall[0].vm_name, "opnsense")
      web_ui     = "https://${cidrhost(var.arch_management_subnet, 1)}"
      interfaces = "5 (WAN + 4 zones)"
    }
  } : null
}
