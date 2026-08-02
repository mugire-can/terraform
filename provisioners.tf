resource "null_resource" "kali_setup" {
  depends_on = [vmworkstation_vm.kali_like]

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = var.kali_ip
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nmap masscan"
    ]
  }
}

resource "null_resource" "victim_setup" {
  depends_on = [vmworkstation_vm.victim]

  connection {
    type     = "ssh"
    user     = var.ssh_user
    password = var.ssh_password
    host     = var.victim_ip
    timeout  = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/labuser/victim_service",
      "nohup python3 -m http.server 8080 --directory /home/labuser/victim_service > /home/labuser/http.log 2>&1 &",
      "sleep 2",
      "ps aux | grep http.server"
    ]
  }
}
