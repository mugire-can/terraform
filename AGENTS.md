# AGENTS.md

## Purpose
This repository provisions and configures a small Debian-based cybersecurity lab on VMware Workstation using Terraform (with optional Ansible post-configuration).

## Repository structure
- `/home/runner/work/terraform/terraform/versions.tf` — Terraform and provider version constraints.
- `/home/runner/work/terraform/terraform/provider.tf` — `vmworkstation` provider authentication and API endpoint.
- `/home/runner/work/terraform/terraform/variables.tf` — all input variables (including sensitive credentials).
- `/home/runner/work/terraform/terraform/main.tf` — VM resources (`kali-like-vm`, `victim-vm`) and outputs.
- `/home/runner/work/terraform/terraform/provisioners.tf` — `remote-exec` bootstrapping for attacker/victim VMs.
- `/home/runner/work/terraform/terraform/inventory.tf` — generated Ansible inventory (`ansible/inventory.ini`).
- `/home/runner/work/terraform/terraform/terraform.tfvars.example` — safe template for local secrets/config.
- `/home/runner/work/terraform/terraform/ansible/playbook.yml` — Ansible configuration for attacker and victim roles.
- `/home/runner/work/terraform/terraform/ansible/ansible.cfg` — Ansible defaults.

## Operating model
1. Terraform creates/clones and configures VM resources.
2. Terraform can run inline `remote-exec` provisioning.
3. Terraform also generates an Ansible inventory for richer post-provisioning.
4. Ansible applies package/service configuration in a cleaner, repeatable way.

## Required workflows
- Initialize and review changes:
  - `terraform init`
  - `terraform plan -parallelism=1`
- Apply and destroy (sequential API calls are required for stability):
  - `terraform apply -parallelism=1`
  - `terraform destroy -parallelism=1`
- Optional Ansible step after apply:
  - `cd /home/runner/work/terraform/terraform/ansible`
  - `ansible-playbook -i inventory.ini playbook.yml`

## Guardrails for agents
- Never commit real credentials, generated state, or `terraform.tfvars`.
- Keep `terraform.tfvars.example` as the only credential template.
- Preserve provider stability constraints unless explicitly validated and tested.
- Keep VMware API interactions serialized (`-parallelism=1`) unless proven safe.
- Prefer idempotent configuration (Ansible/systemd) over long-term shell one-liners.

## Technology improvement path (continuous)
When extending this repository, prefer changes that improve reliability, security, and maintainability:
1. Migrate provisioning logic from ad-hoc `remote-exec` commands to Ansible roles/tasks.
2. Move cleartext SSH/API credentials to a secure secret source for runtime injection.
3. Add automated formatting and validation gates (`terraform fmt -check`, `terraform validate`) in CI.
4. Add static/security checks for IaC and Ansible before merge.
5. Modularize VM definitions if more attacker/victim nodes are introduced.
6. Reduce duplicated values via locals/structured variables.
7. Document tested upgrade paths before changing provider or Terraform versions.

## Change acceptance checklist
For any infrastructure change, ensure:
- Terraform configuration remains valid and readable.
- Existing attacker/victim behavior is preserved unless intentionally changed.
- Generated artifacts and secrets remain excluded from version control.
- Documentation is updated when workflows or structure change.
