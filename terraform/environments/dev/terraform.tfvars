# Development Environment Configuration

platform    = "darwin"
hypervisor  = "fusion"
environment = "dev"

project_name = "cyberlab-dev"

# Reduced resources for development
vm_memory    = 2048
vm_cpus      = 2
vm_disk_size = 30

# Development network (avoid conflicts with production)
network_prefix     = "10.20"
dmz_subnet         = "10.20.1.0/24"
internal_subnet    = "10.20.2.0/24"
management_subnet  = "10.20.3.0/24"
secure_subnet      = "10.20.4.0/24"

# Fewer WireGuard peers for dev
wireguard_peers = 2

# Development-specific settings
debug_mode = true
