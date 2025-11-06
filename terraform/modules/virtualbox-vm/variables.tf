variable "name" {
  description = "VM name"
  type        = string
}

variable "image_url" {
  description = "URL or path to VM image"
  type        = string
  default     = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
}

variable "iso_path" {
  description = "Path to ISO file for installation"
  type        = string
  default     = ""
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

variable "networks" {
  description = "List of network adapters"
  type = list(object({
    type           = string
    host_interface = string
  }))
  default = [
    {
      type           = "hostonly"
      host_interface = "vboxnet0"
    }
  ]
}
