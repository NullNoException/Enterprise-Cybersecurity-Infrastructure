# OPNsense Firewall Configuration
# This file defines the OPNsense firewall VM that sits at the center of the network architecture

locals {
  opnsense_enabled = var.deploy_opnsense && local.use_virtualbox
}

# OPNsense VM - Central Firewall/Router
module "opnsense_firewall" {
  count = local.opnsense_enabled ? 1 : 0

  source = "./modules/virtualbox-vm"

  name      = "${var.project_name}-opnsense"
  image_url = var.opnsense_iso_url
  iso_path  = "${var.iso_path}/${var.opnsense_iso}"

  cpus   = var.opnsense_cpus
  memory = var.opnsense_memory

  # OPNsense needs multiple network interfaces for routing between zones
  networks = [
    # WAN/External Interface (172.25.0.0/24)
    {
      type           = "nat"
      host_interface = ""
    },
    # DMZ Interface (172.25.10.0/24)
    {
      type           = "hostonly"
      host_interface = "vboxnet1"
    },
    # Internal Interface (172.25.20.0/24)
    {
      type           = "hostonly"
      host_interface = "vboxnet2"
    },
    # Security Interface (172.25.30.0/24)
    {
      type           = "hostonly"
      host_interface = "vboxnet3"
    },
    # Management Interface (172.25.40.0/24)
    {
      type           = "hostonly"
      host_interface = "vboxnet4"
    }
  ]
}

# Output OPNsense information
output "opnsense_info" {
  description = "OPNsense firewall information"
  value = local.opnsense_enabled ? {
    vm_id   = module.opnsense_firewall[0].vm_id
    vm_name = module.opnsense_firewall[0].vm_name

    interfaces = {
      wan = {
        interface = "em0"
        network   = "NAT (Internet)"
        purpose   = "External connectivity"
      }
      dmz = {
        interface = "em1"
        network   = var.arch_dmz_subnet
        gateway   = cidrhost(var.arch_dmz_subnet, 1)
        purpose   = "DMZ services (NGINX, T-Pot)"
      }
      internal = {
        interface = "em2"
        network   = var.arch_internal_subnet
        gateway   = cidrhost(var.arch_internal_subnet, 1)
        purpose   = "Internal services (Database, LDAP)"
      }
      security = {
        interface = "em3"
        network   = var.arch_security_subnet
        gateway   = cidrhost(var.arch_security_subnet, 1)
        purpose   = "Security monitoring (Wazuh, Elasticsearch)"
      }
      management = {
        interface = "em4"
        network   = var.arch_management_subnet
        gateway   = cidrhost(var.arch_management_subnet, 1)
        purpose   = "Management interfaces (Grafana, Prometheus)"
      }
    }

    web_ui = "https://${cidrhost(var.arch_management_subnet, 1)}"

    default_credentials = {
      username = "root"
      password = "opnsense"
      note     = "CHANGE IMMEDIATELY AFTER FIRST LOGIN"
    }
  } : null
}
