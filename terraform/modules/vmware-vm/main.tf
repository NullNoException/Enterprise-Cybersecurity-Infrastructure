terraform {
  required_providers {
    vmworkstation = {
      source  = "elsudano/vmworkstation"
      version = "2.0.1"
    }
  }
}

# VMware Workstation/Fusion VM
resource "vmworkstation_vm" "vm" {
  sourceid     = var.template_id
  denomination = var.name
  description  = var.description
  path         = var.vm_path

  # Resource allocation
  numvcpus = var.cpus
  memsize  = var.memory

  # Network configuration
  dynamic "network_adapter" {
    for_each = var.networks
    content {
      type           = "custom"
      network        = network_adapter.value.name
      network_type   = network_adapter.value.type
      adapter_type   = "e1000e"
      start_connected = true
    }
  }

  # Disk configuration
  disk {
    name = "${var.name}.vmdk"
    size = var.disk_size
  }
}

# Output VM information
output "vm_id" {
  description = "VM instance ID"
  value       = vmworkstation_vm.vm.id
}

output "vm_name" {
  description = "VM name"
  value       = vmworkstation_vm.vm.denomination
}

output "vm_path" {
  description = "VM path on disk"
  value       = vmworkstation_vm.vm.path
}
