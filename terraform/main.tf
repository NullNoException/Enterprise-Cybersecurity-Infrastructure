terraform {
  required_version = ">= 1.0"

  required_providers {
    # For Docker containers
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }

    # For VMware Workstation/Fusion
    # vmworkstation = {
    #   source  = "elsudano/vmworkstation"
    #   version = "2.0.1"
    # }

    # For VirtualBox
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

# Provider configurations
provider "docker" {
  host = var.docker_host
}

# VMware Workstation provider (also works with Fusion on macOS)
# provider "vmworkstation" {
#   url      = var.vmware_url
#   user     = var.vmware_user
#   password = var.vmware_password
#   debug    = var.debug_mode
# }

# VirtualBox provider
provider "virtualbox" {
  # VirtualBox doesn't require explicit configuration
}

# Local variables for environment detection
locals {
  is_macos   = var.platform == "darwin" || var.platform == "macos"
  is_windows = var.platform == "windows"
  is_linux   = var.platform == "linux"

  # Determine which hypervisor to use
  use_vmware     = var.hypervisor == "vmware" || var.hypervisor == "fusion"
  use_virtualbox = var.hypervisor == "virtualbox"

  # Network configuration
  network_prefix = var.network_prefix

  # Service deployment strategy
  services = {
    # Services that should run on Docker
    docker_services = [
      "nginx",
      "wazuh-manager",
      "wazuh-indexer",
      "wazuh-dashboard",
      "wireguard"
    ]

    # Services that need VMs (if any custom ones are needed)
    vm_services = var.additional_vms
  }
}
