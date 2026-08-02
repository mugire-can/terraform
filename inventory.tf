# Generates an Ansible inventory file from the current Terraform variables,
# so that Ansible always targets the VMs currently managed by Terraform.
# This is the "going further" enhancement: instead of installing software
# purely through inline remote-exec commands, Terraform hands off the
# configuration step to Ansible, which is easier to extend and maintain.

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.ini"

  content = <<-EOT
  [attacker]
  kali-like-vm ansible_host=${var.kali_ip} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password} ansible_become_pass=${var.ssh_password}

  [victim]
  victim-vm ansible_host=${var.victim_ip} ansible_user=${var.ssh_user} ansible_ssh_pass=${var.ssh_password} ansible_become_pass=${var.ssh_password}

  [lab:children]
  attacker
  victim

  [lab:vars]
  ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT

  depends_on = [
    vmworkstation_vm.kali_like,
    vmworkstation_vm.victim
  ]
}
