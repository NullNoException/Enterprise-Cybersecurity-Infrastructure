# Docker Networks
# These networks map to the defense-in-depth topology

resource "docker_network" "dmz" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name   = "${var.project_name}-dmz"
  driver = "bridge"

  ipam_config {
    subnet  = var.dmz_subnet
    gateway = cidrhost(var.dmz_subnet, 1)
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

resource "docker_network" "internal" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name   = "${var.project_name}-internal"
  driver = "bridge"

  ipam_config {
    subnet  = var.internal_subnet
    gateway = cidrhost(var.internal_subnet, 1)
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

resource "docker_network" "management" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name   = "${var.project_name}-management"
  driver = "bridge"

  ipam_config {
    subnet  = var.management_subnet
    gateway = cidrhost(var.management_subnet, 1)
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

resource "docker_network" "secure" {
  count = local.use_vmware || local.use_virtualbox ? 0 : 1

  name   = "${var.project_name}-secure"
  driver = "bridge"

  ipam_config {
    subnet  = var.secure_subnet
    gateway = cidrhost(var.secure_subnet, 1)
  }

  labels {
    label = "layer"
    value = "secure"
  }

  labels {
    label = "project"
    value = var.project_name
  }

  internal = true  # Secure network is isolated
}

# Output network information
output "docker_networks" {
  description = "Docker network details"
  value = {
    dmz = {
      name   = try(docker_network.dmz[0].name, null)
      subnet = var.dmz_subnet
      id     = try(docker_network.dmz[0].id, null)
    }
    internal = {
      name   = try(docker_network.internal[0].name, null)
      subnet = var.internal_subnet
      id     = try(docker_network.internal[0].id, null)
    }
    management = {
      name   = try(docker_network.management[0].name, null)
      subnet = var.management_subnet
      id     = try(docker_network.management[0].id, null)
    }
    secure = {
      name   = try(docker_network.secure[0].name, null)
      subnet = var.secure_subnet
      id     = try(docker_network.secure[0].id, null)
    }
  }
}
