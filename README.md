Terraform Debian Lab

Infrastructure-as-Code project that uses Terraform to deploy and manage Debian 12 virtual machines on VMware Workstation Pro, including a small two-VM cybersecurity lab (attacker / victim scenario).

Table of contents
Overview
Architecture
Prerequisites
Environment setup
Project files
Terraform workflow
Terraform commands used
Variables
Lifecycle management
Cybersecurity lab scenario
Going further: Ansible integration
Difficulties encountered and solutions
Cleaning up
Knowledge base
Overview

This project automates the deployment of Debian 12 virtual machines using Terraform as the Infrastructure-as-Code (IaC) tool, with VMware Workstation Pro as the hypervisor. It demonstrates:

Deploying a VM by cloning a prepared template
Parameterizing infrastructure with Terraform variables
Managing changes to existing infrastructure (in-place updates)
Tearing down infrastructure cleanly with terraform destroy
Provisioning software on VMs with remote-exec
A minimal cybersecurity lab with two interacting VMs
Architecture
                    VMware Workstation Pro (Windows host)
                                   |
                          vmrest.exe (REST API)
                                   |
                        Terraform + vmworkstation provider
                                   |
              +--------------------+--------------------+
              |                                          |
      kali-like-vm (attacker)                    victim-vm (victim)
      Debian 12 + nmap + masscan                 Debian 12 + Python
                                                  HTTP server :8080
              |                                          |
              +-------------- same network ---------------+
                        (inherited from template,
                         VMware NAT / VMnet8)

Both VMs are clones of a single prepared template (Debian12-Base), so they automatically share the same virtual network configuration as the template.

Prerequisites
Windows host with VMware Workstation Pro installed
A Debian 12 template VM already created, with:
SSH server enabled
Open-VM-Tools installed
A standard user with sudo access
No desktop environment (headless / text-mode)
Terraform CLI installed and available in PATH
vmrest.exe (shipped with VMware Workstation) configured with a username/password, used by Terraform to talk to VMware Workstation
Environment setup
Create the Debian 12 template VM in VMware Workstation (SSH, Open-VM-Tools, sudo user, no GUI). Note the full path to its .vmx file — this is the template Terraform will clone from.
Configure and start the VMware REST API:
powershell
   cd "C:\Program Files (x86)\VMware\VMware Workstation"
   .\vmrest.exe --config      # set a username/password
   .\vmrest.exe               # starts the API on http://127.0.0.1:8697

Keep this process running in a dedicated terminal while using Terraform.

Find the template's VM id via the REST API (needed in main.tf):
powershell
   curl -u <user>:<password> http://127.0.0.1:8697/api/vms
Copy terraform.tfvars.example to terraform.tfvars and fill in your real credentials and IP addresses (this file is git-ignored).
Project files
File	Purpose
versions.tf	Required Terraform version and providers
provider.tf	vmworkstation provider configuration
variables.tf	All input variable declarations
main.tf	The two lab VM resources (attacker + victim)
provisioners.tf	remote-exec provisioners installing tools/services
terraform.tfvars.example	Template for the (git-ignored) terraform.tfvars
.gitignore	Excludes secrets and local Terraform state
Terraform workflow
powershell
terraform init                    # download/install providers
terraform plan                    # preview changes
terraform apply -parallelism=1    # apply changes
terraform destroy                 # tear down infrastructure

-parallelism=1 is used throughout this project because the vmrest REST API does not reliably handle concurrent requests — running actions one at a time avoids random API errors.

Terraform commands used
Command	Effect
terraform init	Downloads the required providers (vmworkstation, random, null) and initializes the working directory. Must be re-run whenever required_providers changes.
terraform plan	Computes and displays the actions Terraform would take (create / update / destroy) without applying them. Used before every apply to review changes.
terraform apply	Executes the plan: creates, updates, or destroys resources to match the configuration. Prompts for confirmation (yes) unless -auto-approve is used.
terraform destroy	Destroys all resources tracked in the Terraform state. Used to tear down the lab cleanly.
terraform plan -destroy	Previews what destroy would remove, without actually removing it.
Variables

Instead of hardcoding values, the following are parameterized through variables.tf / terraform.tfvars:

vmws_user, vmws_password, vmws_url — vmrest API connection
vm_memory, vm_processors — VM hardware sizing
ssh_user, ssh_password — credentials used by remote-exec
kali_ip, victim_ip — IP addresses of the lab VMs

This was validated by changing vm_memory from 1024 to 2048 and vm_processors from 1 to 2 in terraform.tfvars, then running terraform plan / apply: Terraform correctly detected an in-place update (no VM re-creation), and the change was confirmed inside the guest with free -h and nproc.

Lifecycle management
Variables: see above.
Change management: a memory/CPU change was applied to a running VM and Terraform performed an in-place update (~ update in-place), not a destroy/recreate, keeping the VM's identity and data intact.
Destruction: terraform destroy -parallelism=1 was used to remove the VM entirely, both from the VMware Workstation registry and from disk (the .vmx/.vmdk files were deleted along with the folder).
Cybersecurity lab scenario

Two VMs are cloned from the same Debian 12 template:

kali-like-vm (attacker): Debian 12 with nmap and masscan installed via a remote-exec provisioner.

Note: this is not a real Kali Linux image — a genuine Kali base template would be required for that. Here it is a Debian 12 VM equipped with common reconnaissance tools.

victim-vm (victim): Debian 12 running a simple vulnerable HTTP service (python3 -m http.server 8080), started via a remote-exec provisioner.

Both VMs inherit the same virtual network configuration as their template (VMware NAT / VMnet8), so they can reach each other directly.

Verification performed from kali-like-vm:

bash
nmap -p 8080 192.168.233.134
# PORT     STATE SERVICE
# 8080/tcp open  http-proxy

curl http://192.168.233.134:8080/
# <!DOCTYPE HTML> ... Directory listing for / ...

sudo masscan -p8080 192.168.233.134 --rate=1000
# Discovered open port 8080/tcp on 192.168.233.134

This confirms that the attacker VM can scan and successfully interact with the vulnerable service exposed by the victim VM, entirely provisioned through Terraform.

Going further: Ansible integration

As a further improvement over plain remote-exec provisioners, this project also integrates Ansible to configure the lab VMs, which is easier to extend, re-run idempotently, and maintain than inline shell commands.

Terraform is responsible for provisioning (creating the VMs and their network), while Ansible is responsible for configuration (installing packages, deploying a systemd service). This separation of concerns is a common and recommended IaC pattern.

How it works
A local_file Terraform resource (inventory.tf) automatically generates ansible/inventory.ini from the current kali_ip / victim_ip / ssh_user / ssh_password variables, right after the VMs are created:
hcl
   resource "local_file" "ansible_inventory" {
     filename = "${path.module}/ansible/inventory.ini"
     content  = <<-EOT
     [attacker]
     kali-like-vm ansible_host=${var.kali_ip} ansible_user=${var.ssh_user} ...

     [victim]
     victim-vm ansible_host=${var.victim_ip} ansible_user=${var.ssh_user} ...
     EOT
   }
ansible/playbook.yml then configures each host group:
attacker: installs nmap and masscan via the apt module
victim: deploys the vulnerable HTTP service as a proper systemd unit (victim-http.service) instead of a background nohup process, so it survives reboots and is managed like a real service (systemctl status victim-http)
Running it
powershell
terraform apply -parallelism=1     # creates the VMs + inventory.ini
cd ansible
ansible-playbook -i inventory.ini playbook.yml

Note: if running Ansible from WSL against a project folder mounted from Windows (/mnt/d/...), Ansible may ignore ansible.cfg because the directory is reported as world-writable. Passing -i inventory.ini explicitly avoids relying on ansible.cfg for the inventory path.

Requires sshpass on the control machine (used by Ansible for password-based SSH, e.g. via WSL: sudo apt install sshpass), and ansible-core installed (pip install ansible).

This does not replace the remote-exec provisioners already validated in provisioners.tf (kept as-is since they were verified to work end-to-end); it demonstrates an alternative, more maintainable configuration path suitable for evolving the lab further (e.g. adding more tools, more victim services, or more VMs) without touching Terraform code.

Difficulties encountered and solutions
Difficulty	Cause	Solution
terraform command not recognized after choco install	PowerShell was not run as Administrator; Chocolatey lock file could not be acquired	Re-ran PowerShell as Administrator and re-installed
vmrest.exe --config inconsistent credentials	Config and server were run under different Windows sessions (different vmrest.cfg locations)	Ran --config and the server itself in the same elevated session
Provider path issues with the template .vmx	Folder/file names contained spaces (Debian 12-Base)	Renamed the VM folder and files to remove spaces (Debian12-Base)
terraform apply failing on VM creation with newer provider versions	elsudano/vmworkstation v2.x has a known Windows bug causing a Go panic on VM creation	Pinned the provider to the stable 1.0.4 version
terraform destroy failing with "The virtual machine has been locked"	A VMware Workstation console tab for the VM was still open, holding a lock	Closed the console tab in VMware Workstation before retrying
SSH "REMOTE HOST IDENTIFICATION HAS CHANGED" warning	A DHCP-assigned IP was reused by a different VM (different host key) after a previous VM was destroyed	Cleared the stale entry with ssh-keygen -R <ip>
New VMs not visible in the VMware Workstation GUI library	VMs created/managed via the vmrest API are not automatically added to the GUI's VM list	Manually added them via File → Open pointing to their .vmx path
terraform apply looping between "update in-place" and "not powered off" errors for description	The provider does not correctly read back the description attribute from the API, so Terraform always sees it as changed; updating it requires the VM to be powered off	Added lifecycle { ignore_changes = [description] } to both VM resources
remote-exec provisioner failing with dial tcp ... i/o timeout	The VM had been powered off as a side effect of the description update loop above	Powered the VMs back on and fixed the root cause (ignore_changes)
remote-exec provisioner failing with SSH authentication failed	The vmrest API password had mistakenly been reused as the SSH password in terraform.tfvars (these are two different credentials)	Corrected ssh_password to match the actual Debian user's SSH password
No IP attribute exposed by the vmworkstation_vm resource	The provider does not expose the guest IP as a computed Terraform attribute, so it cannot be referenced directly by remote-exec	Queried the IP manually via the vmrest API (GET /api/vms/{id}/ip) after the first apply, then supplied it as a Terraform variable for a second apply that runs the provisioners
ansible.cfg silently ignored, "No inventory was parsed"	Ansible refuses to read ansible.cfg from a world-writable directory, which is the default permission mode for files accessed through a WSL drvfs mount (/mnt/d/...)	Passed the inventory explicitly with ansible-playbook -i inventory.ini playbook.yml instead of relying on ansible.cfg
New victim-http.service (systemd) failed with exit-code / "Address already in use"	Port 8080 was already held by the older Python process started earlier by the remote-exec provisioner (nohup); both provisioning methods (Terraform remote-exec and the Ansible playbook) were trying to manage the same service	Killed the stale process (pkill -f "http.server 8080") then restarted the systemd unit (systemctl restart victim-http.service), which then ran correctly
Cleaning up
powershell
terraform destroy -parallelism=1

Make sure the target VM's console tab is closed in VMware Workstation beforehand to avoid the "virtual machine has been locked" error described above.

Knowledge base
terraform-provider-vmworkstation (elsudano)
Terraform Registry
Terraform Installation