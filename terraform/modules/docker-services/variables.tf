variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "image" {
  description = "Docker image to use"
  type        = string
}

variable "networks" {
  description = "Networks to attach the container to"
  type = list(object({
    name         = string
    ipv4_address = optional(string)
  }))
  default = []
}

variable "ports" {
  description = "Port mappings"
  type = list(object({
    internal = number
    external = number
    protocol = optional(string, "tcp")
  }))
  default = []
}

variable "volumes" {
  description = "Volume mounts"
  type = list(object({
    volume_name    = optional(string)
    host_path      = optional(string)
    container_path = string
    read_only      = optional(bool, false)
  }))
  default = []
}

variable "environment_vars" {
  description = "Environment variables"
  type        = list(string)
  default     = []
}

variable "capabilities_add" {
  description = "Linux capabilities to add"
  type        = list(string)
  default     = []
}

variable "sysctls" {
  description = "Sysctl options"
  type        = map(string)
  default     = {}
}

variable "ulimits" {
  description = "Ulimit options"
  type = list(object({
    name = string
    soft = number
    hard = number
  }))
  default = []
}

variable "labels" {
  description = "Container labels"
  type        = map(string)
  default     = {}
}

variable "restart_policy" {
  description = "Restart policy"
  type        = string
  default     = "unless-stopped"
}

variable "privileged" {
  description = "Run container in privileged mode"
  type        = bool
  default     = false
}
