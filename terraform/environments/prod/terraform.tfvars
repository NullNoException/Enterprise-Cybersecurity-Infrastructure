# Production Environment Configuration

platform    = "darwin"
hypervisor  = "fusion"
environment = "prod"

project_name = "cyberlab-prod"

# Production resources
vm_memory    = 4096
vm_cpus      = 4
vm_disk_size = 60

# Production network
network_prefix     = "10.10"
dmz_subnet         = "10.10.1.0/24"
internal_subnet    = "10.10.2.0/24"
management_subnet  = "10.10.3.0/24"
secure_subnet      = "10.10.4.0/24"

# More WireGuard peers for production
wireguard_peers = 10

# Production settings
debug_mode = false

# Example production VMs
additional_vms = [
  {
    name      = "kali-linux-prod"
    memory    = 4096
    cpus      = 4
    disk_size = 60
    network   = "management"
    os_iso    = "kali-linux-2024.iso"
  }
]
