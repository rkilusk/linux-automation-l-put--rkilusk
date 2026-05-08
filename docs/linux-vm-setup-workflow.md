# Linux VM Setup Workflow (PoC)

## Overview

- Workflow file: `.github/workflows/linux-vm-setup.yml`
- Playbooks:
  - `ansible/playbooks/vm_setup/preflight.yml`
  - `ansible/playbooks/vm_setup/apply.yml`
- Inventory file: `ansible/inventory/ssh/hosts.yml`
- Group vars directory: `ansible/inventory/ssh/group_vars/`

## Trigger

- `workflow_dispatch` only
  - `target_group`: `linux_vm_setup_t0|linux_vm_setup_t1|linux_vm_setup_t2`
  - `arc_tier`: `T0|T1|T2`
  - `run_lint`: run lint/syntax job
  - `allow_partial_setup`: if `true`, missing admin key / NTP files are skipped
  - `confirm_apply`: must be `YES`

## Required Secrets

- `ANSIBLE_SSH_PRIVATE_KEY`
- `ARC_SCRIPT_T0`
- `ARC_SCRIPT_T1`
- `ARC_SCRIPT_T2`

## Optional Files

If these files are missing and `allow_partial_setup=true`, corresponding tasks are skipped:

- Admin SSH keys:
  - `ansible/files/admin1.pub`
  - `ansible/files/admin2.pub`
  - `ansible/files/admin3.pub`
- NTP drop-ins:
  - `ansible/files/50-evr-ntp-deb.conf`
  - `ansible/files/50-evr-ntp-ocl.conf`
