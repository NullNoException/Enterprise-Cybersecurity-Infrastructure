variable "name" {
  description = "VM name"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
  default     = "Managed by Terraform"
}

variable "template_id" {
  description = "Source template/image ID"
  type        = string
  default     = ""
}

variable "vm_path" {
  description = "Path where VM files will be stored"
  type        = string
}

variable "cpus" {
  description = "Number of CPUs"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 40
}

variable "networks" {
  description = "List of networks to attach"
  type = list(object({
    name = string
    type = string
  }))
  default = []
}
