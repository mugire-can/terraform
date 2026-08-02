variable "vmws_user" {
  type        = string
  description = "VMware Workstation REST API username"
}

variable "vmws_password" {
  type        = string
  description = "VMware Workstation REST API password"
  sensitive   = true
}

variable "vmws_url" {
  type        = string
  description = "VMware Workstation REST API URL"
  default     = "http://127.0.0.1:8697/api"
}

variable "vm_memory" {
  type        = number
  description = "Memory size in MB for the VM"
  default     = 1024
}

variable "vm_processors" {
  type        = number
  description = "Number of processors for the VM"
  default     = 1
}

variable "vm_name_prefix" {
  type        = string
  description = "Prefix used for the VM name"
  default     = "debian-lab"
}

variable "ssh_user" {
  type        = string
  description = "SSH username for the Debian VMs"
  default     = "labuser"
}

variable "ssh_password" {
  type        = string
  description = "SSH password for the Debian VMs"
  sensitive   = true
}

variable "kali_ip" {
  type        = string
  description = "IP address of the kali-like-vm (obtained after first apply)"
}

variable "victim_ip" {
  type        = string
  description = "IP address of the victim-vm (obtained after first apply)"
}