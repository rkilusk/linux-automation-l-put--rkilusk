# vCenter Snapshot Workflow (PoC)

## Overview

- Workflow file: `.github/workflows/vcenter-snapshot.yml`
- Playbooks:
  - `ansible/playbooks/vcenter/preflight.yml`
  - `ansible/playbooks/vcenter/create.yml`
  - `ansible/playbooks/vcenter/delete.yml`
- Inventory file: `ansible/inventory/vcenter/hosts.yml`
- Group vars directory: `ansible/inventory/vcenter/group_vars/`
- Inventory groups:
  - `linux_snapshot_t1`
  - `linux_snapshot_t0`
  - `linux_snapshot_targets` (parent group)

## Triggers

- `workflow_dispatch`
  - `operation`: `create` or `delete`
  - `target_group`: `linux_snapshot_t1`, `linux_snapshot_t0`, `linux_snapshot_targets`
  - `retention_days`: default `3`
  - `run_lint`: default `true`
  - `confirm_delete`: must be `YES` for manual delete
- `schedule` (`Europe/Tallinn`)
  - `45 1 * * 3` -> create scheduler (Wednesday 01:45 local time)
  - `30 5 * * 6` -> delete scheduler (Saturday 05:30 local time)

Create schedule logic validates tier windows against `Europe/Tallinn` local date:

- T1: second Wednesday (day 8..14) -> create snapshot
- T0: third Wednesday (day 15..21) -> create snapshot
- Delete retention cleanup runs weekly on Saturday with retention policy (default `3` days).

## Required secrets

- `VMWARE_HOST`
- `VMWARE_USER`
- `VMWARE_PASSWORD`

## Required host/group vars

- `cluster_name` / `datacenter_name` are now metadata only for this workflow.
- Optional:
  - `vm_folder` (optional metadata)
  - `vm_name` (default `inventory_hostname`)
  - `cluster_name` (metadata placeholder for future targeting/reporting)
  - `esxi_host_name` (metadata placeholder for future targeting/reporting)
- In current PoC layout, per-VM variables are defined inline under each host in `ansible/inventory/vcenter/hosts.yml`.
- Runtime VM location is discovered automatically via `community.vmware.vmware_guest_find` by VM name.

Defaults in `ansible/inventory/vcenter/group_vars/linux_snapshot_targets.yml`:

- `snapshot_prefix: enne-turvauuendust-`
- `snapshot_retention_days: 3`
- `snapshot_serial: 3`
- `vmware_validate_certs: false`
