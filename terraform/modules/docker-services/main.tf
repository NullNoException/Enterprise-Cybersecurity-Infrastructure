terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6.2"
    }
  }
}

# Generic Docker container module
resource "docker_container" "service" {
  name  = var.container_name
  image = docker_image.service.image_id

  # Networks
  dynamic "networks_advanced" {
    for_each = var.networks
    content {
      name         = networks_advanced.value.name
      ipv4_address = networks_advanced.value.ipv4_address
    }
  }

  # Ports
  dynamic "ports" {
    for_each = var.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
      protocol = try(ports.value.protocol, "tcp")
    }
  }

  # Volumes
  dynamic "volumes" {
    for_each = var.volumes
    content {
      volume_name    = try(volumes.value.volume_name, null)
      host_path      = try(volumes.value.host_path, null)
      container_path = volumes.value.container_path
      read_only      = try(volumes.value.read_only, false)
    }
  }

  # Environment variables
  env = var.environment_vars

  # Capabilities
  dynamic "capabilities" {
    for_each = length(var.capabilities_add) > 0 ? [1] : []
    content {
      add = var.capabilities_add
    }
  }

  # Sysctls
  sysctls = var.sysctls

  # Ulimits
  dynamic "ulimit" {
    for_each = var.ulimits
    content {
      name = ulimit.value.name
      soft = ulimit.value.soft
      hard = ulimit.value.hard
    }
  }

  # Labels
  dynamic "labels" {
    for_each = var.labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  restart    = var.restart_policy
  privileged = var.privileged
}

resource "docker_image" "service" {
  name = var.image
}

# Outputs
output "container_id" {
  description = "Container ID"
  value       = docker_container.service.id
}

output "container_name" {
  description = "Container name"
  value       = docker_container.service.name
}

output "image_id" {
  description = "Image ID"
  value       = docker_image.service.image_id
}
