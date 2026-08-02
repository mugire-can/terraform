resource "vmworkstation_vm" "kali_like" {
  sourceid     = "IBVRPHMGD2VS992C8NDBAGOVPKN6HS8J"
  denomination = "kali-like-vm"
  description  = "Attacker VM - Debian 12 with security tools"
  path         = "D:\\kali-like-vm\\kali-like-vm.vmx"
  processors   = var.vm_processors
  memory       = var.vm_memory

  lifecycle {
    ignore_changes = [description]
  }
}

resource "vmworkstation_vm" "victim" {
  sourceid     = "IBVRPHMGD2VS992C8NDBAGOVPKN6HS8J"
  denomination = "victim-vm"
  description  = "Victim VM - Debian 12 with vulnerable service"
  path         = "D:\\victim-vm\\victim-vm.vmx"
  processors   = var.vm_processors
  memory       = var.vm_memory

  lifecycle {
    ignore_changes = [description]
  }
}

output "kali_vm_id" {
  value = vmworkstation_vm.kali_like.id
}

output "victim_vm_id" {
  value = vmworkstation_vm.victim.id
}