terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

# VirtualBox VM
resource "virtualbox_vm" "vm" {
  name   = var.name
  image  = var.image_url
  cpus   = var.cpus
  memory = var.memory

  # Network configuration
  dynamic "network_adapter" {
    for_each = var.networks
    content {
      type           = network_adapter.value.type
      device         = "IntelPro1000MTServer"
      host_interface = network_adapter.value.host_interface
    }
  }

  # Optical drive for ISO
  optical_disks = var.iso_path != "" ? [var.iso_path] : []

  # Status
  status = "running"
}

# Output VM information
output "vm_id" {
  description = "VM instance ID"
  value       = virtualbox_vm.vm.id
}

output "vm_name" {
  description = "VM name"
  value       = virtualbox_vm.vm.name
}

output "vm_network_adapters" {
  description = "Network adapter information"
  value       = virtualbox_vm.vm.network_adapter
}
