# Platform and Hypervisor Configuration
variable "platform" {
  description = "Operating system platform (darwin/macos, windows, linux)"
  type        = string
  default     = "darwin"

  validation {
    condition     = contains(["darwin", "macos", "windows", "linux"], var.platform)
    error_message = "Platform must be one of: darwin, macos, windows, linux"
  }
}

variable "hypervisor" {
  description = "Hypervisor to use for VMs (vmware, fusion, virtualbox)"
  type        = string
  default     = "fusion"

  validation {
    condition     = contains(["vmware", "fusion", "virtualbox"], var.hypervisor)
    error_message = "Hypervisor must be one of: vmware, fusion, virtualbox"
  }
}

# Docker Configuration
variable "docker_host" {
  description = "Docker daemon host URL"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

# VMware Configuration
variable "vmware_url" {
  description = "VMware Workstation/Fusion API URL"
  type        = string
  default     = "http://localhost:8697/api"
}

variable "vmware_user" {
  description = "VMware API username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "vmware_password" {
  description = "VMware API password"
  type        = string
  default     = ""
  sensitive   = true
}

# Network Configuration
variable "network_prefix" {
  description = "Network prefix for all infrastructure (e.g., 10.10)"
  type        = string
  default     = "10.10"
}

variable "dmz_subnet" {
  description = "DMZ subnet CIDR"
  type        = string
  default     = "10.10.1.0/24"
}

variable "internal_subnet" {
  description = "Internal subnet CIDR"
  type        = string
  default     = "10.10.2.0/24"
}

variable "management_subnet" {
  description = "Management subnet CIDR"
  type        = string
  default     = "10.10.3.0/24"
}

variable "secure_subnet" {
  description = "Secure subnet CIDR"
  type        = string
  default     = "10.10.4.0/24"
}

# VM Configuration
variable "vm_memory" {
  description = "Default memory for VMs in MB"
  type        = number
  default     = 4096
}

variable "vm_cpus" {
  description = "Default CPU count for VMs"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Default disk size for VMs in GB"
  type        = number
  default     = 40
}

variable "additional_vms" {
  description = "List of additional VMs to create (beyond Docker services)"
  type = list(object({
    name      = string
    memory    = optional(number, 4096)
    cpus      = optional(number, 2)
    disk_size = optional(number, 40)
    network   = string
    os_iso    = optional(string, "")
  }))
  default = []
}

# ISO and Image Configuration
variable "iso_path" {
  description = "Path to ISO files directory"
  type        = string
  default     = "./iso"
}

variable "default_os_iso" {
  description = "Default OS ISO file name"
  type        = string
  default     = "ubuntu-22.04-server-amd64.iso"
}

# Docker Image Configuration
variable "wazuh_version" {
  description = "Wazuh version to deploy"
  type        = string
  default     = "4.8.2"
}

variable "nginx_image" {
  description = "NGINX Docker image"
  type        = string
  default     = "nginx:alpine"
}

# Project Configuration
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cyberlab"
}

variable "environment" {
  description = "Environment name (dev, prod, test)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, prod, test"
  }
}

# Debug Configuration
variable "debug_mode" {
  description = "Enable debug mode for providers"
  type        = bool
  default     = false
}

# WireGuard Configuration
variable "wireguard_port" {
  description = "WireGuard VPN port"
  type        = number
  default     = 51820
}

variable "wireguard_peers" {
  description = "Number of WireGuard peer configurations to generate"
  type        = number
  default     = 5
}

# Service Ports
variable "nginx_http_port" {
  description = "NGINX HTTP port"
  type        = number
  default     = 80
}

variable "nginx_https_port" {
  description = "NGINX HTTPS port"
  type        = number
  default     = 443
}

variable "wazuh_api_port" {
  description = "Wazuh API port"
  type        = number
  default     = 55000
}

variable "wazuh_registration_port" {
  description = "Wazuh agent registration port"
  type        = number
  default     = 1514
}

variable "wazuh_cluster_port" {
  description = "Wazuh cluster communication port"
  type        = number
  default     = 1516
}

# Architecture Deployment Configuration
variable "deploy_architecture" {
  description = "Deploy the full 5-network architecture from docs/ARCHITECTURE.md"
  type        = bool
  default     = false
}

variable "deploy_opnsense" {
  description = "Deploy OPNsense firewall VM"
  type        = bool
  default     = false
}

# Architecture Network Configuration (from docs/ARCHITECTURE.md)
variable "arch_external_subnet" {
  description = "External/VPN network subnet"
  type        = string
  default     = "172.25.0.0/24"
}

variable "arch_dmz_subnet" {
  description = "DMZ network subnet (public-facing services)"
  type        = string
  default     = "172.25.10.0/24"
}

variable "arch_internal_subnet" {
  description = "Internal network subnet (protected services)"
  type        = string
  default     = "172.25.20.0/24"
}

variable "arch_security_subnet" {
  description = "Security network subnet (monitoring and analysis)"
  type        = string
  default     = "172.25.30.0/24"
}

variable "arch_management_subnet" {
  description = "Management network subnet (admin interfaces)"
  type        = string
  default     = "172.25.40.0/24"
}

# OPNsense Configuration
variable "opnsense_cpus" {
  description = "CPU cores for OPNsense VM"
  type        = number
  default     = 2
}

variable "opnsense_memory" {
  description = "Memory in MB for OPNsense VM"
  type        = number
  default     = 2048
}

variable "opnsense_iso" {
  description = "OPNsense ISO filename"
  type        = string
  default     = "OPNsense-24.1-dvd-amd64.iso"
}

variable "opnsense_iso_url" {
  description = "URL to download OPNsense ISO"
  type        = string
  default     = "https://mirror.ams1.nl.leaseweb.net/opnsense/releases/24.1/OPNsense-24.1-dvd-amd64.iso.bz2"
}
