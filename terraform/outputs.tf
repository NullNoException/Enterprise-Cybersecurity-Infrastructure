# Output configuration for Terraform deployment

output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    platform    = var.platform
    hypervisor  = var.hypervisor
    environment = var.environment
    project     = var.project_name
  }
}

output "network_configuration" {
  description = "Network topology information"
  value = {
    dmz = {
      subnet  = var.dmz_subnet
      gateway = cidrhost(var.dmz_subnet, 1)
    }
    internal = {
      subnet  = var.internal_subnet
      gateway = cidrhost(var.internal_subnet, 1)
    }
    management = {
      subnet  = var.management_subnet
      gateway = cidrhost(var.management_subnet, 1)
    }
    secure = {
      subnet  = var.secure_subnet
      gateway = cidrhost(var.secure_subnet, 1)
    }
  }
}

output "access_information" {
  description = "Access URLs and endpoints"
  value = {
    wazuh_dashboard = "https://localhost:5601"
    wazuh_api       = "https://localhost:${var.wazuh_api_port}"
    nginx_http      = "http://localhost:${var.nginx_http_port}"
    nginx_https     = "https://localhost:${var.nginx_https_port}"
    wireguard_port  = var.wireguard_port
  }
  sensitive = false
}

output "credentials_reminder" {
  description = "Reminder about default credentials"
  value = {
    warning = "CHANGE DEFAULT CREDENTIALS IMMEDIATELY"
    wazuh = {
      username = "admin"
      note     = "Password set in docker-services.tf or VM configuration"
    }
    wireguard = {
      configs = "Check WireGuard volume for peer configurations"
      path    = "docker volume inspect ${var.project_name}-wireguard-config"
    }
  }
}

output "next_steps" {
  description = "Post-deployment actions"
  value = <<-EOT

  DEPLOYMENT COMPLETE!

  Next Steps:
  1. Verify all services are running:
     - Docker: docker ps
     - VMware: Check VMware Workstation/Fusion console
     - VirtualBox: VBoxManage list runningvms

  2. Access services:
     - Wazuh Dashboard: https://localhost:5601
     - NGINX Reverse Proxy: https://localhost:${var.nginx_https_port}

  3. Configure WireGuard VPN:
     - Retrieve peer configs: docker exec ${var.project_name}-wireguard cat /config/peer1/peer1.conf
     - Import to WireGuard client

  4. Security hardening:
     - Change default passwords
     - Configure SSL certificates
     - Review firewall rules
     - Enable 2FA where applicable

  5. Documentation:
     - Review docs/DEPLOYMENT_CHECKLIST.md
     - Read docs/WAZUH_SETUP.md
     - Check logs: docker logs <container-name>

  For issues, check:
  - terraform.tfstate for resource IDs
  - Docker logs: docker logs <container>
  - VM console: Check hypervisor interface

  EOT
}
